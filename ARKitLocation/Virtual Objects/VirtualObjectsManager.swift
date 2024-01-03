//
//  AppDelegate.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import Foundation
import os.log

class VirtualObjectsManager {

	static let shared = VirtualObjectsManager()

	// AutoIncrement Unique Id
	private var nextID = 1
	func generateUid() -> Int {
		nextID += 1
		return nextID
	}

	private var virtualObjects: [VirtualObject] = [VirtualObject]()
	private var virtualObjectSelected: VirtualObject?

	func addVirtualObject(virtualObject: VirtualObject) {
		virtualObjects.append(virtualObject)
	}

	func resetVirtualObjects() {
		for object in virtualObjects {
			object.unloadModel()
			object.removeFromParentNode()
		}
		virtualObjectSelected = nil
		virtualObjects = []
	}

	func isAVirtualObjectPlaced() -> Bool {
		return virtualObjectSelected != nil
	}

	func setVirtualObjectSelected(virtualObject: VirtualObject) {
		self.virtualObjectSelected = virtualObject
	}

	func getVirtualObjectSelected() -> VirtualObject? {
		return self.virtualObjectSelected
	}
}
