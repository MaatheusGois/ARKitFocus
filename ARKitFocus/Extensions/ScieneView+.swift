//
//  ScieneView+.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import Foundation
import SceneKit

extension ARSCNView {

    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/environment_blur.exr") {
                scene.lightingEnvironment.contents = environmentMap
            }
        }
        scene.lightingEnvironment.intensity = intensity
    }
}
