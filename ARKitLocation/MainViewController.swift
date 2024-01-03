//
//  AppDelegate.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import Foundation
import SceneKit
import UIKit
import Photos

class MainViewController: UIViewController {
	var dragOnInfinitePlanesEnabled = false
	var currentGesture: Gesture?

	var use3DOFTrackingFallback = false
	var screenCenter: CGPoint?

	let session = ARSession()
	var sessionConfig: ARConfiguration = ARWorldTrackingConfiguration()

	var trackingFallbackTimer: Timer?

	// Use average of recent virtual object distances to avoid rapid changes in object scale.
	var recentVirtualObjectDistances = [CGFloat]()

	let DEFAULT_DISTANCE_CAMERA_TO_OBJECTS = Float(10)

	override func viewDidLoad() {
        super.viewDidLoad()

        setupScene()
		setupFocusSquare()
		resetVirtualObject()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		UIApplication.shared.isIdleTimerDisabled = true
		restartPlaneDetection()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		session.pause()
	}

    // MARK: - ARKit / ARSCNView
    var use3DOFTracking = false {
		didSet {
			if use3DOFTracking {
				sessionConfig = ARWorldTrackingConfiguration()
			}
//			sessionConfig.isLightEstimationEnabled = true
			session.run(sessionConfig)
		}
	}
	@IBOutlet var sceneView: ARSCNView!

    // MARK: - Ambient Light Estimation
	func toggleAmbientLightEstimation(_ enabled: Bool) {
        if enabled {
			if !sessionConfig.isLightEstimationEnabled {
				sessionConfig.isLightEstimationEnabled = true
				session.run(sessionConfig)
			}
        } else {
			if sessionConfig.isLightEstimationEnabled {
				sessionConfig.isLightEstimationEnabled = false
				session.run(sessionConfig)
			}
        }
    }

    // MARK: - Virtual Object Loading
	var isLoadingObject: Bool = false {
		didSet {
			DispatchQueue.main.async {
				self.addObjectButton.isEnabled = !self.isLoadingObject
				self.restartExperienceButton.isEnabled = !self.isLoadingObject
			}
		}
	}

	@IBOutlet weak var addObjectButton: UIButton!

	@IBAction func chooseObject(_ button: UIButton) {
        loadVirtualObject(object: Vase())
    }

    // MARK: - Planes

	var planes = [ARPlaneAnchor: Plane]()

    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {

//		let pos = SCNVector3.positionFromTransform(anchor.transform)

		let plane = Plane(anchor)

		planes[anchor] = plane
		node.addChildNode(plane)
	}

	func restartPlaneDetection() {
		// configure session
		if let worldSessionConfig = sessionConfig as? ARWorldTrackingConfiguration {
			worldSessionConfig.planeDetection = .horizontal
			session.run(worldSessionConfig, options: [.resetTracking, .removeExistingAnchors])
		}

		// reset timer
		if trackingFallbackTimer != nil {
			trackingFallbackTimer!.invalidate()
			trackingFallbackTimer = nil
		}
	}

    // MARK: - Focus Square
    var focusSquare: FocusSquare?

    func setupFocusSquare() {
		focusSquare?.isHidden = true
		focusSquare?.removeFromParentNode()
		focusSquare = FocusSquare()
		sceneView.scene.rootNode.addChildNode(focusSquare!)
    }

	func updateFocusSquare() {
		guard let screenCenter = screenCenter else { return }

		let virtualObject = VirtualObjectsManager.shared.getVirtualObjectSelected()
		if virtualObject != nil && sceneView.isNode(virtualObject!, insideFrustumOf: sceneView.pointOfView!) {
			focusSquare?.hide()
		} else {
			focusSquare?.unhide()
		}
		let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position)
		if let worldPos = worldPos {
			focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
		}
	}

    // MARK: - UI Elements and Actions

	@IBOutlet weak var restartExperienceButton: UIButton!
	var restartExperienceButtonIsEnabled = true

	@IBAction func restartExperience(_ sender: Any) {
		guard restartExperienceButtonIsEnabled, !isLoadingObject else {
			return
		}

		DispatchQueue.main.async {
			self.restartExperienceButtonIsEnabled = false
			self.use3DOFTracking = false

			self.setupFocusSquare()
//			self.loadVirtualObject()
			self.restartPlaneDetection()

			self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])

			// Disable Restart button for five seconds in order to give the session enough time to restart.
			DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
				self.restartExperienceButtonIsEnabled = true
			})
		}
	}

	// MARK: - Error handling

	func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
		if allowRestart {
            self.restartExperience(self)
		}
	}
}

// MARK: - ARKit / ARSCNView
extension MainViewController {
	func setupScene() {
		sceneView.setUp(viewController: self, session: session)
		DispatchQueue.main.async {
			self.screenCenter = self.sceneView.bounds.mid
		}
	}

	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		switch camera.trackingState {
		case .notAvailable:
            break
		case .limited:
			if use3DOFTrackingFallback {
				// After 10 seconds of limited quality, fall back to 3DOF mode.
				trackingFallbackTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { _ in
					self.use3DOFTracking = true
					self.trackingFallbackTimer?.invalidate()
					self.trackingFallbackTimer = nil
				})
			}
		case .normal:
			if use3DOFTrackingFallback && trackingFallbackTimer != nil {
				trackingFallbackTimer!.invalidate()
				trackingFallbackTimer = nil
			}
		}
	}

	func session(_ session: ARSession, didFailWithError error: Error) {
		guard let arError = error as? ARError else { return }

		let nsError = error as NSError
		var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
		if let recoveryOptions = nsError.localizedRecoveryOptions {
			for option in recoveryOptions {
				sessionErrorMsg.append("\(option).")
			}
		}

		let isRecoverable = (arError.code == .worldTrackingFailed)
		if isRecoverable {
			sessionErrorMsg += "\nYou can try resetting the session or quit the application."
		} else {
			sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
		}

		displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
	}

	func sessionWasInterrupted(_ session: ARSession) {
	}

	func sessionInterruptionEnded(_ session: ARSession) {
		session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
		restartExperience(self)
	}
}

// MARK: Gesture Recognized
extension MainViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
			return
		}

		if currentGesture == nil {
			currentGesture = Gesture.startGestureFromTouches(touches, self.sceneView, object)
		} else {
			currentGesture = currentGesture!.updateGestureFromTouches(touches, .touchBegan)
		}

		displayVirtualObjectTransform()
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			return
		}
		currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
		displayVirtualObjectTransform()
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			chooseObject(addObjectButton)
			return
		}

		currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
			return
		}
		currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
	}
}

// MARK: - VirtualObjectSelectionViewControllerDelegate
extension MainViewController {

	func loadVirtualObject(object: VirtualObject) {
		// Show progress indicator
		let spinner = UIActivityIndicatorView()
		spinner.center = addObjectButton.center
		spinner.bounds.size = CGSize(width: addObjectButton.bounds.width - 5, height: addObjectButton.bounds.height - 5)
		addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
		sceneView.addSubview(spinner)
		spinner.startAnimating()

		DispatchQueue.global().async {
			self.isLoadingObject = true
			object.viewController = self
			VirtualObjectsManager.shared.addVirtualObject(virtualObject: object)
			VirtualObjectsManager.shared.setVirtualObjectSelected(virtualObject: object)

			object.loadModel()

			DispatchQueue.main.async {
				if let lastFocusSquarePos = self.focusSquare?.lastPosition {
					self.setNewVirtualObjectPosition(lastFocusSquarePos)
				} else {
					self.setNewVirtualObjectPosition(SCNVector3Zero)
				}

				spinner.removeFromSuperview()

				// Update the icon of the add object button
				let buttonImage = UIImage.composeButtonImage(from: object.thumbImage)
				let pressedButtonImage = UIImage.composeButtonImage(from: object.thumbImage, alpha: 0.3)
				self.addObjectButton.setImage(buttonImage, for: [])
				self.addObjectButton.setImage(pressedButtonImage, for: [.highlighted])
				self.isLoadingObject = false
			}
		}
	}
}

// MARK: - ARSCNViewDelegate
extension MainViewController: ARSCNViewDelegate {
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		DispatchQueue.main.async {
			self.updateFocusSquare()
			// If light estimation is enabled, update the intensity of the model's lights and the environment map
			if let lightEstimate = self.session.currentFrame?.lightEstimate {
				self.sceneView.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40)
			} else {
				self.sceneView.enableEnvironmentMapWithIntensity(25)
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor {
				self.addPlane(node: node, anchor: planeAnchor)
				self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor)
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor {
				if let plane = self.planes[planeAnchor] {
					plane.update(planeAnchor)
				}
				self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor)
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor, let plane = self.planes.removeValue(forKey: planeAnchor) {
				plane.removeFromParentNode()
			}
		}
	}
}

// MARK: Virtual Object Manipulation
extension MainViewController {
	func displayVirtualObjectTransform() {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let cameraTransform = session.currentFrame?.camera.transform else {
			return
		}

		// Output the current translation, rotation & scale of the virtual object as text.
		let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
		let vectorToCamera = cameraPos - object.position

		let distanceToUser = vectorToCamera.length()

		var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360
		if angleDegrees < 0 {
			angleDegrees += 360
		}

		let distance = String(format: "%.2f", distanceToUser)
		let scale = String(format: "%.2f", object.scale.x)
		print("Distance: \(distance) m\nRotation: \(angleDegrees)°\nScale: \(scale)x")
	}

	func moveVirtualObjectToPosition(_ pos: SCNVector3?, _ instantly: Bool, _ filterPosition: Bool) {

		guard let newPosition = pos else {
            print("CANNOT PLACE OBJECT\nTry moving left or right.")
			// Reset the content selection in the menu only if the content has not yet been initially placed.
			if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
				resetVirtualObject()
			}
			return
		}

		if instantly {
			setNewVirtualObjectPosition(newPosition)
		} else {
			updateVirtualObjectPosition(newPosition, filterPosition)
		}
	}

	func worldPositionFromScreenPosition(_ position: CGPoint,
	                                     objectPos: SCNVector3?,
	                                     infinitePlane: Bool = false) -> (position: SCNVector3?,
																		  planeAnchor: ARPlaneAnchor?,
																		  hitAPlane: Bool) {

		// -------------------------------------------------------------------------------
		// 1. Always do a hit test against exisiting plane anchors first.
		//    (If any such anchors exist & only within their extents.)

		let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
		if let result = planeHitTestResults.first {

			let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
			let planeAnchor = result.anchor

			// Return immediately - this is the best possible outcome.
			return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
		}

		// -------------------------------------------------------------------------------
		// 2. Collect more information about the environment by hit testing against
		//    the feature point cloud, but do not return the result yet.

		var featureHitTestPosition: SCNVector3?
		var highQualityFeatureHitTestResult = false

		let highQualityfeatureHitTestResults =
			sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)

		if !highQualityfeatureHitTestResults.isEmpty {
			let result = highQualityfeatureHitTestResults[0]
			featureHitTestPosition = result.position
			highQualityFeatureHitTestResult = true
		}

		// -------------------------------------------------------------------------------
		// 3. If desired or necessary (no good feature hit test result): Hit test
		//    against an infinite, horizontal plane (ignoring the real world).

		if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {

			let pointOnPlane = objectPos ?? SCNVector3Zero

			let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
			if pointOnInfinitePlane != nil {
				return (pointOnInfinitePlane, nil, true)
			}
		}

		// -------------------------------------------------------------------------------
		// 4. If available, return the result of the hit test against high quality
		//    features if the hit tests against infinite planes were skipped or no
		//    infinite plane was hit.

		if highQualityFeatureHitTestResult {
			return (featureHitTestPosition, nil, false)
		}

		// -------------------------------------------------------------------------------
		// 5. As a last resort, perform a second, unfiltered hit test against features.
		//    If there are no features in the scene, the result returned here will be nil.

		let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
		if !unfilteredFeatureHitTestResults.isEmpty {
			let result = unfilteredFeatureHitTestResults[0]
			return (result.position, nil, false)
		}

		return (nil, nil, false)
	}

	func setNewVirtualObjectPosition(_ pos: SCNVector3) {

		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let cameraTransform = session.currentFrame?.camera.transform else {
			return
		}

		recentVirtualObjectDistances.removeAll()

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
		var cameraToPosition = pos - cameraWorldPos
		cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)

		object.position = cameraWorldPos + cameraToPosition

		if object.parent == nil {
			sceneView.scene.rootNode.addChildNode(object)
		}
	}

	func resetVirtualObject() {
		VirtualObjectsManager.shared.resetVirtualObjects()

		addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
		addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
	}

	func updateVirtualObjectPosition(_ pos: SCNVector3, _ filterPosition: Bool) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
			return
		}

		guard let cameraTransform = session.currentFrame?.camera.transform else {
			return
		}

		let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
		var cameraToPosition = pos - cameraWorldPos
		cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)

		let hitTestResultDistance = CGFloat(cameraToPosition.length())

		recentVirtualObjectDistances.append(hitTestResultDistance)
		recentVirtualObjectDistances.keepLast(10)

		if filterPosition {
			let averageDistance = recentVirtualObjectDistances.average!

			cameraToPosition.setLength(Float(averageDistance))
			let averagedDistancePos = cameraWorldPos + cameraToPosition

			object.position = averagedDistancePos
		} else {
			object.position = cameraWorldPos + cameraToPosition
		}
	}

	func checkIfObjectShouldMoveOntoPlane(anchor: ARPlaneAnchor) {
		guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
			let planeAnchorNode = sceneView.node(for: anchor) else {
			return
		}

		// Get the object's position in the plane's coordinate system.
		let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)

		if objectPos.y == 0 {
			return; // The object is already on the plane
		}

		// Add 10% tolerance to the corners of the plane.
		let tolerance: Float = 0.1

		let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
		let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
		let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
		let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance

		if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
			return
		}

		// Drop the object onto the plane if it is near it.
		let verticalAllowance: Float = 0.03
		if objectPos.y > -verticalAllowance && objectPos.y < verticalAllowance {
            print("OBJECT MOVED\nSurface detected nearby")

			SCNTransaction.begin()
			SCNTransaction.animationDuration = 0.5
			SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
			object.position.y = anchor.transform.columns.3.y
			SCNTransaction.commit()
		}
	}
}
