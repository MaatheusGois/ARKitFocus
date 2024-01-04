//
//  VirtualObjectsManager.swift
//  ARKitLocation
//
//  Created by Matheus Gois on 03/01/24.
//

import Foundation

final class VirtualObjectsManager {

    static let shared = VirtualObjectsManager()

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
