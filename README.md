# In Time

**A stylized, third-person courier game built in Godot 4.**

"In Time" is a grey-box prototype exploring arcade movement mechanics within a compressed, "theme park" representation of the West Midlands. The project aims to capture a PS1-era aesthetic while implementing rigorous modern movement logic.

## 🛠️ Technical Highlights

This project was built to explore complex character controller architectures and vector-based movement physics without relying on default engine character controllers.

### 1. Finite State Machine (FSM) Architecture
To manage the complexity of a character that can transition between parkour, driving, and standard traversal, I implemented a strict **Finite State Machine**.
* **Decoupled Logic:** Each state (`Idle`, `Run`, `Air`, `Bike`, `Climb`) is encapsulated, preventing spaghetti code in the `_physics_process`.
* **Transition Integrity:** Transitions are guarded to ensure valid states (e.g., you cannot transition to `Climb` unless the surface normal check returns a valid wall vector).

### 2. Vector Math & Quake-Style Air Movement
The core movement loop moves beyond standard acceleration to implement "Quake-style" air strafing, requiring direct manipulation of velocity vectors.
* **Air Control:** I calculate the dot product between the current velocity and the player's input direction ("wish direction") to apply acceleration only when it doesn't exceed the max air speed cap.
* **Result:** This allows players to curve their trajectory in mid-air by turning the camera and inputting lateral movement, preserving momentum.

### 3. The "Pants Principle" Vehicle System
Rather than utilizing a separate `RigidBody3D` for the bicycle, I utilized the "Pants Principle" (illusion of complexity).
* **State Swapping:** When the player mounts the bike, they simply enter the `BikeState`. The character mesh is swapped, and the collision capsule is adjusted.
* **Arcade Physics:** Instead of simulating complex wheel friction, I implemented custom drift logic by modifying the linear velocity vector's slide angle relative to the input vector. This creates a "snappy" arcade feel similar to *Crazy Taxi* rather than a simulation.

### 4. Collision-Based Climbing
Climbing is handled via raycasts and vector math rather than predefined animation zones.
* **Wall Snapping:** The system calculates the inverse of the wall's surface normal to "snap" the player rotation to face the wall perfectly upon contact.
* **Mantling:** Height checks determine if the player is at a ledge, triggering a vertical vector impulse to hoist the player up.

## 🗺️ World Design
* **Theme Park Map:** The West Midlands is condensed into a dense, interconnected playground layout designed for flow and momentum.
* **Traffic Systems:** Hazards are managed using `PathFollow3D` nodes to create deterministic traffic patterns for the player to dodge.

## 💻 Tech Stack
* **Engine:** Godot 4 (Compatibility Renderer)
* **Language:** GDScript
* **Version Control:** Git

## Current Status
The project is currently in the **Grey-Box Prototype** phase.
* Core FSM Controller (Walk, Run, Jump, Air Strafe)
* Bicycle Vehicle State with Drifting
* Climbing & Mantling
* Traffic Hazards
* *In Progress:* Art asset pipeline and shader implementation for PS1 aesthetic.

---
*Created by Gabriel Knight*
