//
//  ViewController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/03/2015.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var distanceRunView: UIView!
  @IBOutlet weak var timeRunView: UIView!
  @IBOutlet weak var distancePickerView: UIPickerView!
  @IBOutlet weak var timePickerView: UIPickerView!
  
  @IBOutlet weak var goBtn: UIButton!
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var feedbackBtn: UIButton!
  
  override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  @IBAction func goRunning(sender: AnyObject) {
    performSegueWithIdentifier("", sender: nil)
  }
  
  @IBAction func feedbackAction(sender: AnyObject) {
    performSegueWithIdentifier("", sender: nil)
  }
  
}

