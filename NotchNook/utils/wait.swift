//
//  wait.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import Foundation

func wait(_ seconds: Double) async {
  try? await Task.sleep(until: .now + .seconds(seconds), clock: .continuous)
}
