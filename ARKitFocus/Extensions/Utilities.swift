//
//  Utilities.swift
//  ARKitFocus
//
//  Created by Matheus Gois on 03/01/24.
//

import ARKit
import Foundation

// MARK: - Collection extensions

extension Array where Iterator.Element == CGFloat {
    var average: CGFloat? {
        guard !isEmpty else {
            return nil
        }

        var ret = reduce(CGFloat(0)) { cur, next -> CGFloat in
            var cur = cur
            cur += next
            return cur
        }
        let fcount = CGFloat(count)
        ret /= fcount
        return ret
    }
}

extension Array where Iterator.Element == SCNVector3 {
    var average: SCNVector3? {
        guard !isEmpty else {
            return nil
        }

        var ret = reduce(SCNVector3Zero) { cur, next -> SCNVector3 in
            var cur = cur
            cur.x += next.x
            cur.y += next.y
            cur.z += next.z
            return cur
        }
        let fcount = Float(count)
        ret.x /= fcount
        ret.y /= fcount
        ret.z /= fcount

        return ret
    }
}

extension RangeReplaceableCollection {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - SCNNode extension

extension SCNNode {

    func setUniformScale(_ scale: Float) {
        self.scale = SCNVector3Make(scale, scale, scale)
    }

    func renderOnTop() {
        renderingOrder = 2
        if let geom = geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = false
            }
        }
        for child in childNodes {
            child.renderOnTop()
        }
    }

    func removeAllChildren() {
        for child in childNodes {
            child.removeFromParentNode()
        }
    }
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {

    init(_ vec: vector_float3) {
        self.init(vec.x, vec.y, vec.z)
    }

    func length() -> Float {
        sqrtf(x * x + y * y + z * z)
    }

    mutating func setLength(_ length: Float) {
        normalize()
        self *= length
    }

    mutating func setMaximumLength(_ maxLength: Float) {
        if length() <= maxLength {
            return
        } else {
            normalize()
            self *= maxLength
        }
    }

    mutating func normalize() {
        self = normalized()
    }

    func normalized() -> SCNVector3 {
        if length() == 0 {
            return self
        }

        return self / length()
    }

    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    func dot(_ vec: SCNVector3) -> Float {
        (x * vec.x) + (y * vec.y) + (z * vec.z)
    }

    func cross(_ vec: SCNVector3) -> SCNVector3 {
        SCNVector3(y * vec.z - z * vec.y, z * vec.x - x * vec.z, x * vec.y - y * vec.x)
    }
}

func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
    SCNVector3Make(Float(value), Float(value), Float(value))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func *= (left: inout SCNVector3, right: Float) {
    left = left * right
}

// MARK: - SCNMaterial extensions

extension SCNMaterial {

    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = true
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}

// MARK: - CGPoint extensions

extension CGPoint {

    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }

    func length() -> CGFloat {
        sqrt(x * x + y * y)
    }

    func midpoint(_ point: CGPoint) -> CGPoint {
        (self + point) / 2
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x / right, y: left.y / right)
}

// MARK: - CGRect extensions

extension CGRect {

    var mid: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {

    let direction = direction.normalized()

    // Special case handling: Check if the ray is horizontal as well.
    if direction.y == 0 {
        if rayOrigin.y == planeY {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.
            return rayOrigin
        } else {
            // The ray is parallel to the plane and never intersects.
            return nil
        }
    }

    // The distance from the ray's origin to the intersection point on the plane is:
    //   (pointOnPlane - rayOrigin) dot planeNormal
    //  --------------------------------------------
    //          direction dot planeNormal

    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    let dist = (planeY - rayOrigin.y) / direction.y

    // Do not return intersections behind the ray's origin.
    if dist < 0 {
        return nil
    }

    // Return the intersection point.
    return rayOrigin + (direction * dist)
}

extension ARSCNView {

    struct HitTestRay {
        let origin: SCNVector3
        let direction: SCNVector3
    }

    func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {

        guard let frame = session.currentFrame else {
            return nil
        }

        let cameraPos = SCNVector3.positionFromTransform(frame.camera.transform)

        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1)
        let screenPosOnFarClippingPlane = unprojectPoint(positionVec)

        var rayDirection = screenPosOnFarClippingPlane - cameraPos
        rayDirection.normalize()

        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }

    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {
        guard let ray = hitTestRayFromScreenPos(point) else {
            return nil
        }

        if ray.direction.y > -0.03 {
            return nil
        }

        return rayIntersectionWithHorizontalPlane(
            rayOrigin: ray.origin,
            direction: ray.direction,
            planeY: pointOnPlane.y
        )
    }

    struct FeatureHitTestResult {
        let position: SCNVector3
        let distanceToRayOrigin: Float
        let featureHit: SCNVector3
        let featureDistanceToHitResult: Float
    }

    func hitTestWithFeatures(
        _ point: CGPoint,
        coneOpeningAngleInDegrees: Float,
        minDistance: Float = 0,
        maxDistance: Float = Float.greatestFiniteMagnitude,
        maxResults: Int = 1
    ) -> [FeatureHitTestResult] {

        var results = [FeatureHitTestResult]()

        guard let features = session.currentFrame?.rawFeaturePoints else {
            return results
        }

        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }

        let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = ((maxAngleInDeg / 180) * Float.pi)

        let points = features.__points

        for i in 0...features.__count {

            let feature = points.advanced(by: Int(i))
            let featurePos = SCNVector3(feature.pointee)

            let originToFeature = featurePos - ray.origin

            let crossProduct = originToFeature.cross(ray.direction)
            let featureDistanceFromResult = crossProduct.length()

            let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
            let hitTestResultDistance = (hitTestResult - ray.origin).length()

            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                // Skip this feature - it is too close or too far away.
                continue
            }

            let originToFeatureNormalized = originToFeature.normalized()
            let angleBetweenRayAndFeature = acos(ray.direction.dot(originToFeatureNormalized))

            if angleBetweenRayAndFeature > maxAngle {
                // Skip this feature - is is outside of the hit test cone.
                continue
            }

            // All tests passed: Add the hit against this feature to the results.
            results.append(FeatureHitTestResult(
                position: hitTestResult,
                distanceToRayOrigin: hitTestResultDistance,
                featureHit: featurePos,
                featureDistanceToHitResult: featureDistanceFromResult
            ))
        }

        // Sort the results by feature distance to the ray.
        results = results.sorted(by: { first, second -> Bool in
            first.distanceToRayOrigin < second.distanceToRayOrigin
        })

        // Cap the list to maxResults.
        var cappedResults = [FeatureHitTestResult]()
        var i = 0
        while i < maxResults, i < results.count {
            cappedResults.append(results[i])
            i += 1
        }

        return cappedResults
    }

    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {

        var results = [FeatureHitTestResult]()

        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }

        if let result = hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
            results.append(result)
        }

        return results
    }

    func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {

        guard let features = session.currentFrame?.rawFeaturePoints else {
            return nil
        }

        let points = features.__points

        var closestFeaturePoint = origin
        var minDistance = Float.greatestFiniteMagnitude

        for i in 0...features.__count {
            let feature = points.advanced(by: Int(i))
            let featurePos = SCNVector3(feature.pointee)

            let originVector = origin - featurePos
            let crossProduct = originVector.cross(direction)
            let featureDistanceFromResult = crossProduct.length()

            if featureDistanceFromResult < minDistance {
                closestFeaturePoint = featurePos
                minDistance = featureDistanceFromResult
            }
        }

        // Compute the point along the ray that is closest to the selected feature.
        let originToFeature = closestFeaturePoint - origin
        let hitTestResult = origin + (direction * direction.dot(originToFeature))
        let hitTestResultDistance = (hitTestResult - origin).length()

        return FeatureHitTestResult(
            position: hitTestResult,
            distanceToRayOrigin: hitTestResultDistance,
            featureHit: closestFeaturePoint,
            featureDistanceToHitResult: minDistance
        )
    }
}
