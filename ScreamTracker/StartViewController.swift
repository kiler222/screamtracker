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
    
    @IBAction func toToSavedScreams(_ sender: Any) {
        performSegue(withIdentifier: "goToSavedScreams", sender: self)
    }
    
    
    
    @IBAction func goToScreamTracking(_ sender: Any) {
    performSegue(withIdentifier: "goToScreamTracking", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
