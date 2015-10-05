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
  private let minutes = 30
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return minutes
  }
  
  func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
    let view = UILabel()
    view.text = "\((row + 1) * 5):00 mins"
    view.textAlignment = .Center
    view.textColor = UIColor.blackColor()
    view.font = UIFont(name: "Helvetica", size: 32)
    return view
  }
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    
  }
  
  func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 60.0
  }
}