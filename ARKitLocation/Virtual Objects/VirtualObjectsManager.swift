//
//  VirtualObjectsManager.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import Foundation

class VirtualObjectsManager {

    static let shared = VirtualObjectsManager()

    // AutoIncrement Unique Id
    private var nextID = 1
    func generateUid() -> Int {
        nextID += 1
        return nextID
    }

    private var virtualObjects = [VirtualObject]()
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
        virtualObjectSelected != nil
    }

    func setVirtualObjectSelected(virtualObject: VirtualObject) {
        virtualObjectSelected = virtualObject
    }

    func getVirtualObjectSelected() -> VirtualObject? {
        virtualObjectSelected
    }
}
