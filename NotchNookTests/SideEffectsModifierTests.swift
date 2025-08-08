//
//  SideEffectsModifierTests.swift
//  NotchNook
//
//  Created by Lori Montenegro on 15/04/25.
//

import XCTest
@testable import NotchNook

final class SideEffectsModifierTests: XCTestCase {

    func testShouldShowChangelog() {
        let modifier = NotchView.SideEffectsModifier(
            viewModel: NotchViewModel(),
            showIndicator: { _, _ in },
            screen: NSScreen.main!
        )
        
        let showChangelogCases = [
            ("1.0.0", "2.0.0"),
            ("1.0.0", "1.1.0"),
            ("", "1.0.0"),
            ("1.0.0", ""),
        ]
        
        let hideChangelogCases = [
            ("1.0.0", "1.0.0"),
            ("1.0.1", "1.0.2"),
            ("", ""),
        ]
        
        // Test changelog should be shown cases
        for (lastVersion, currentVersion) in showChangelogCases {
            XCTAssertTrue(
                modifier.shouldShowChangelog(lastVersionNumber: lastVersion, currentVersionNumber: currentVersion),
                "Changelog should be shown when changing from \(lastVersion) to \(currentVersion)"
            )
        }
        
        // Test changelog should NOT be shown cases
        for (lastVersion, currentVersion) in hideChangelogCases {
            XCTAssertFalse(
                modifier.shouldShowChangelog(lastVersionNumber: lastVersion, currentVersionNumber: currentVersion),
                "Changelog should NOT be shown when changing from \(lastVersion) to \(currentVersion)"
            )
        }
    }
    
    // Additional edge case test
    func testShouldShowChangelogWithInvalidVersionFormats() {
        let modifier = NotchView.SideEffectsModifier(
            viewModel: NotchViewModel(),
            showIndicator: { _, _ in },
            screen: NSScreen.main!
        )
        
        let edgeCases = [
            ("1", "2"),
            ("1.0", "1.1"),
            ("invalid", "valid"),
        ]
        
        for (lastVersion, currentVersion) in edgeCases {
            let result = modifier.shouldShowChangelog(lastVersionNumber: lastVersion, currentVersionNumber: currentVersion)
            XCTAssertTrue(result, "Should handle edge case of \(lastVersion) to \(currentVersion)")
        }
    }

}
