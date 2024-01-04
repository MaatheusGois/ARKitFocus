//
//  VirtualObjectsManager.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 03/01/24.
//

import Foundation

final class VirtualObjectsManager {

    private var virtualObjects = [VirtualObject]()

    var selected: VirtualObject?

    init(selected: VirtualObject? = nil) {
        self.selected = selected
    }

    func addVirtualObject(virtualObject: VirtualObject) {
        virtualObjects.append(virtualObject)
    }

    func resetVirtualObjects() {
        for object in virtualObjects {
            object.unloadModel()
            object.removeFromParentNode()
        }
        virtualObjects = []
    }
}
