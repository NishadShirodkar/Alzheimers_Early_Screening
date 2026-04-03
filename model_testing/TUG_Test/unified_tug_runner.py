import os
import sys
import time
from pathlib import Path


def import_major_tasks(major_dir: Path):
    """Import the existing sit/stand task functions without modifying their code."""
    previous_cwd = Path.cwd()

    try:
        os.chdir(major_dir)
        if str(major_dir) not in sys.path:
            sys.path.insert(0, str(major_dir))

        from tasks.sit_to_stand_task import run_sit_to_stand
        from tasks.stand_to_sit_task import run_stand_to_sit

        return run_sit_to_stand, run_stand_to_sit
    finally:
        os.chdir(previous_cwd)


def resolve_pose_model(base_dir: Path) -> Path:
    """Find the existing MediaPipe pose model used by the walk scripts."""
    candidates = [
        base_dir / "pose_landmarker_full.task",
        base_dir / "walk-f and b" / "pose_landmarker_full.task",
        base_dir / "main" / "pose_landmarker_full.task",
    ]

    for candidate in candidates:
        if candidate.exists():
            return candidate

    raise FileNotFoundError("pose_landmarker_full.task not found in TUG_Test")


def create_pose_landmarker(model_path: Path):
    import mediapipe as mp

    mp_pose = mp.tasks.vision.PoseLandmarker
    BaseOptions = mp.tasks.BaseOptions
    PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions
    VisionRunningMode = mp.tasks.vision.RunningMode

    options = PoseLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(model_path)),
        running_mode=VisionRunningMode.VIDEO,
    )

    return mp_pose.create_from_options(options)


def run_walk_phase(cap, base_dir: Path) -> bool:
    """Inline the existing walk logic so the same camera session stays open."""
    import cv2
    import mediapipe as mp
    import numpy as np

    model_path = resolve_pose_model(base_dir)
    landmarker = create_pose_landmarker(model_path)

    patient_id = input("Enter Patient ID: ")
    age = int(input("Enter Age: "))

    age_group = "Young Adults"
    forward_ref, forward_sd = 2.2, 0.4
    backward_ref, backward_sd = 2.0, 0.6

    hip_positions = []
    timestamps = []

    state = "WAIT"
    state_start = time.time()

    forward_window = 6
    backward_window = 6
    motion_threshold = 8

    walk_started_forward = False
    walk_started_backward = False
    prev_hip = None

    print("\nClick camera window and press S")

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.flip(frame, 1)
            _, frame_width, _ = frame.shape

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

            timestamp_ms = int(time.time() * 1000)
            result = landmarker.detect_for_video(mp_image, timestamp_ms)

            key = cv2.waitKey(1) & 0xFF
            elapsed = time.time() - state_start

            if state == "WAIT":
                cv2.putText(frame, "Press S to Start Test",
                            (90, 250), cv2.FONT_HERSHEY_SIMPLEX,
                            1, (0, 255, 255), 3)

                if key == ord('s'):
                    hip_positions.clear()
                    timestamps.clear()
                    state = "COUNTDOWN"
                    state_start = time.time()

            elif state == "COUNTDOWN":
                remain = 3 - int(elapsed)

                cv2.putText(frame, f"Starting in {remain}",
                            (120, 250), cv2.FONT_HERSHEY_SIMPLEX,
                            2, (0, 0, 255), 5)

                if elapsed >= 3:
                    state = "FORWARD"
                    walk_started_forward = False
                    prev_hip = None
                    state_start = time.time()

            elif state == "FORWARD":
                cv2.putText(frame, "WALK FORWARD",
                            (70, 60), cv2.FONT_HERSHEY_SIMPLEX,
                            1.3, (0, 255, 0), 4)

                if result.pose_landmarks and len(result.pose_landmarks) > 0:
                    lm = result.pose_landmarks[0]
                    hip_x = ((lm[23].x + lm[24].x) / 2) * frame_width

                    if prev_hip is not None:
                        motion = abs(hip_x - prev_hip)
                        if motion > motion_threshold and not walk_started_forward:
                            walk_started_forward = True
                            state_start = time.time()
                            print("Forward walking detected")

                    prev_hip = hip_x

                    if walk_started_forward:
                        hip_positions.append(hip_x)
                        timestamps.append(time.time())
                else:
                    print("No person detected")

                if walk_started_forward and elapsed >= forward_window:
                    state = "BACKWARD"
                    walk_started_backward = False
                    prev_hip = None
                    state_start = time.time()

            elif state == "BACKWARD":
                cv2.putText(frame, "NOW WALK BACK",
                            (60, 60), cv2.FONT_HERSHEY_SIMPLEX,
                            1.3, (255, 200, 0), 4)

                if result.pose_landmarks and len(result.pose_landmarks) > 0:
                    lm = result.pose_landmarks[0]
                    hip_x = ((lm[23].x + lm[24].x) / 2) * frame_width

                    if prev_hip is not None:
                        motion = abs(hip_x - prev_hip)
                        if motion > motion_threshold and not walk_started_backward:
                            walk_started_backward = True
                            state_start = time.time()
                            print("Backward walking detected")

                    prev_hip = hip_x

                    if walk_started_backward:
                        hip_positions.append(hip_x)
                        timestamps.append(time.time())
                else:
                    print("No person detected")

                if walk_started_backward and elapsed >= backward_window:
                    state = "DONE"

            elif state == "DONE":
                cv2.putText(frame, "TEST COMPLETE",
                            (80, 250), cv2.FONT_HERSHEY_SIMPLEX,
                            2, (255, 0, 0), 5)

            cv2.imshow("Walking Assessment", frame)

            if state == "DONE":
                cv2.waitKey(2000)
                print("\nWalk phase completed")
                break

            if key == ord('q'):
                break

        hip_positions_array = np.array(hip_positions)
        timestamps_array = np.array(timestamps)

        if len(hip_positions_array) < 20:
            print("\nNot enough walking data captured.")
            return False

        velocity = np.gradient(hip_positions_array) / np.gradient(timestamps_array)
        forward_mask = velocity < -15
        backward_mask = velocity > 15

        def duration(mask):
            start = None
            total = 0
            for index in range(len(mask)):
                if mask[index] and start is None:
                    start = timestamps_array[index]
                elif not mask[index] and start is not None:
                    total += timestamps_array[index] - start
                    start = None
            return total

        forward_time = duration(forward_mask)
        backward_time = duration(backward_mask)

        def interpret(value, ref, sd):
            if value > ref + sd:
                return "Longer than expected range"
            if value < ref - sd:
                return "Faster than expected range"
            return "Within expected range"

        print("\n======================================")
        print("        WALKING ASSESSMENT REPORT")
        print("======================================\n")
        print(f"Patient ID      : {patient_id}")
        print(f"Age             : {age}")
        print(f"Age Group       : {age_group}")
        print(f"Assessment Date : {time.strftime('%d %B %Y')}")
        print("\n--------------------------------------")
        print("\n1️⃣ Walking Forward")
        print(f"Measured Duration : {round(forward_time, 2)} seconds")
        print(f"Reference Range   : {forward_ref} ± {forward_sd}")
        print(f"Observation       : {interpret(forward_time, forward_ref, forward_sd)}")
        print("\n2️⃣ Walking Backward")
        print(f"Measured Duration : {round(backward_time, 2)} seconds")
        print(f"Reference Range   : {backward_ref} ± {backward_sd}")
        print(f"Observation       : {interpret(backward_time, backward_ref, backward_sd)}")
        print("\n--------------------------------------")
        print("Overall Interpretation:")
        print("Temporal walking performance evaluated")
        print("against age-related reference values.")
        print("\n======================================")
        return True

    except Exception as exc:
        print(f"Walk phase failed: {exc}")
        return False

    finally:
        landmarker.close()
        cv2.destroyAllWindows()


def main() -> None:
    base_dir = Path(__file__).resolve().parent
    major_dir = base_dir / "Major project- dementia"
    walk_dir = base_dir / "walk-f and b"

    if not major_dir.exists():
        print(f"Missing folder: {major_dir}")
        return

    run_sit_to_stand, run_stand_to_sit = import_major_tasks(major_dir)

    import cv2

    print("Unified TUG Runner")
    print("This runs your existing scripts in one continuous camera session:")
    print("1) Sit-to-Stand")
    print("2) Walk Forward/Back")
    print("3) Stand-to-Sit")

    input("\nPress Enter to start the unified flow...")

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Camera could not be opened.")
        return

    previous_cwd = Path.cwd()

    try:
        os.chdir(major_dir)
        print("\n[Stage] Sit-to-Stand task")
        run_sit_to_stand(cap)

        input("\nSit-to-Stand done. Press Enter to continue to walking stage...")

        os.chdir(walk_dir)
        ok = run_walk_phase(cap, base_dir)
        if not ok:
            print("\nStopped at Walk stage.")
            return

        input("\nWalk stage done. Press Enter to continue to Stand-to-Sit...")

        os.chdir(major_dir)
        print("\n[Stage] Stand-to-Sit task")
        run_stand_to_sit(cap)

        print("\nUnified TUG flow completed.")
        print("Reports are saved by the existing scripts in their current report locations.")

    finally:
        os.chdir(previous_cwd)
        cap.release()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
