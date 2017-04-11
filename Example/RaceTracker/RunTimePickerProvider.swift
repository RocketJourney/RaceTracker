//
//  RunTimePickerProvider.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class RunTimePickerProvider:NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
  var updateValue:UpdateValueBlock?
  fileprivate let minutes = 30
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return minutes
  }
  
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    let view = UILabel()
    view.text = "\((row + 1) * 5):00 mins"
    view.textAlignment = .center
    view.textColor = UIColor.black
    view.font = UIFont(name: "Helvetica", size: 32)
    return view
  }
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    updateValue?(value: row)
  }
  
  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 60.0
  }
}
