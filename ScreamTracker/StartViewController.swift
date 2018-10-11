//
//  StartViewController.swift
//  ScreamTracker
//
//  Created by kiler on 08.10.2018.
//  Copyright © 2018 kiler. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

   var licznik = 0
    
    @IBOutlet weak var startTrackingButton: UIButton!
    
    @IBAction func toToSavedScreams(_ sender: Any) {
        performSegue(withIdentifier: "goToSavedScreams", sender: self)
    }
    
    
    @IBOutlet weak var goToSavedButton: UIButton!
    
    @IBAction func goToScreamTracking(_ sender: Any) {
    performSegue(withIdentifier: "goToScreamTracking", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTrackingButton.layer.cornerRadius = 5
        startTrackingButton.clipsToBounds = false
        
        // shadow
        startTrackingButton.layer.shadowColor = UIColor.black.cgColor
        startTrackingButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        startTrackingButton.layer.shadowOpacity = 0.7
        startTrackingButton.layer.shadowRadius = 4.0
//
        
        goToSavedButton.layer.cornerRadius = 5
        goToSavedButton.clipsToBounds = false
        goToSavedButton.layer.shadowColor = UIColor.black.cgColor
        goToSavedButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        goToSavedButton.layer.shadowOpacity = 0.7
        goToSavedButton.layer.shadowRadius = 4.0
        //
        
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
