//
//  Lab2_AITests.swift
//  Lab2_AITests
//
//  Created by Alexandr on 01/10/2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import XCTest

@testable import Lab2_AI

class Lab2_AITests: XCTestCase {
    
    var viewController: ViewController!
 
    override func setUp() {
        viewController = ViewController()
    }

    override func tearDown() {
        viewController = nil
    }

    func testCPUMembershipFunction() {
        let delta = 0.01
        var x = 0.0
        
        while x < 100 {
            let (low, mid, high) = viewController.cpuMembershipFunction(tCPU: x)
            XCTAssertEqual(low + mid + high, 1)
            x += delta
        }
    }
    
    func testGPUMembershipFunction() {
        let delta = 0.01
        var x = 0.0
        
        while x < 110 {
            let (low, mid, high) = viewController.gpuMembershipFunction(tGPU: x)
            XCTAssertEqual(low + mid + high, 1)
            x += delta
        }
    }

    func testBodyFansMembershipFunction() {
        let delta = 0.1
        var x = 0.0
        
        while x < 2000 {
            let (low, mid, high) = viewController.bodyFansSpeedMembershipFunction(speedFans: x)
            XCTAssertEqual(low + mid + high, 1)
            x += delta
        }
    }

}
