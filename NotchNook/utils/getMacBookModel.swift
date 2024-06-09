//
//  getMacBookModel.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation

func getMacBookModel() -> String? {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
}
