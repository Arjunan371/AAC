//
//  AssessmentConfig.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import Foundation

struct AssessmentConfig: Codable {
    var enableCamera: Bool = true
    var enableMicrophone: Bool = true
    var enableScreenRecord: Bool = true
    var enableFaceDetection: Bool = true
    var timeLimitSeconds: Int = 3600
    var allowTabSwitch: Bool = false
    var enableGuidedAccess: Bool = true
}
