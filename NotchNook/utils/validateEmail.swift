//
//  validateEmail.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/06/24.
//

import Foundation

func validateEmail(_ enteredEmail:String) -> Bool {
    let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
    return emailPredicate.evaluate(with: enteredEmail)

}
