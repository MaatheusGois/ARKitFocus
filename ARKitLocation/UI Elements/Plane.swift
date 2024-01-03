//
//  AppDelegate.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import Foundation
import ARKit

class Plane: SCNNode {

	var anchor: ARPlaneAnchor
	let occlusionPlaneVerticalOffset: Float = -0.01  // The occlusion plane should be placed 1 cm below the actual
													// plane to avoid z-fighting etc.

	var focusSquare: FocusSquare?

	init(_ anchor: ARPlaneAnchor) {
		self.anchor = anchor

		super.init()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func update(_ anchor: ARPlaneAnchor) {
		self.anchor = anchor
	}

}
