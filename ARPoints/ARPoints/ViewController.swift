//
//  ViewController.swift
//  ARPoints
//
//  Created by Josh Robbins on 18/05/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

public var oldPoints: Array<Array<Float>> = Array();
public var MAXPOINT = 300

public var pos: ARCamera? = nil

public var connectURL: String = "http://10.42.0.1:8000"
public var threshold: Float = 0.2
public var magnitude: Float = 0.0
public var MAXSOUNDS: Float = 1.0
public var MINSOUNDS: Float = 0.0
public var increaseAmount: Float = 0.05
public var player: AVAudioPlayer!
public var startTime: Double = 0
public var duration: Double = 0.7


extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //1. Check Our Frame Is Valid & That We Have Received Our Raw Feature Points
        guard let currentFrame = self.augmentedRealitySession.currentFrame,
             let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
        
        pos = currentFrame.camera
        
        //2. Visualize The Feature Points
        visualizeFeaturePointsIn(featurePointsArray)
        
        //3. Update Our Status View
        DispatchQueue.main.async {
            
            //1. Update The Tracking Status
            self.statusLabel.text = self.augmentedRealitySession.sessionStatus()
            
            //2. If We Have Nothing To Report Then Hide The Status View & Shift The Settings Menu
            if let validSessionText = self.statusLabel.text{
                
                self.sessionLabelView.isHidden = validSessionText.isEmpty
            }
            
            if self.sessionLabelView.isHidden { self.settingsConstraint.constant = 100 } else { self.settingsConstraint.constant = 0 }
        }
    
    }
    
    /// Provides Visualization Of Raw Feature Points Detected In The ARSessopm
    ///
    /// - Parameter featurePointsArray: [vector_float3]
    func visualizeFeaturePointsIn(_ featurePointsArray: [vector_float3]){
        
        //1. Remove Any Existing Nodes
        
        if oldPoints.count > MAXPOINT {
            oldPoints = Array(oldPoints[0 ..< MAXPOINT])
        }
        
        self.augmentedRealityView.scene.rootNode.enumerateChildNodes { (featurePoint, _) in
            /*if !oldPoints.contains { p in
                return (p[0] == featurePoint.position.x) && (p[1] == featurePoint.position.y) && (p[2] == featurePoint.position.z)
            } {
                featurePoint.geometry = nil
                featurePoint.removeFromParentNode()
            }*/
            
            featurePoint.geometry = nil
            featurePoint.removeFromParentNode()
        }
 
        
        //2. Update Our Label Which Displays The Count Of Feature Points
        DispatchQueue.main.async {
            self.rawFeaturesLabel.text = self.Feature_Label_Prefix + String(featurePointsArray.count)
        }
        
        //3. Loop Through The Feature Points & Add Them To The Hierachy
        featurePointsArray.forEach { (pointLocation) in
            
            //Clone The SphereNode To Reduce CPU
            let clone = sphereNode.clone()
            clone.position = SCNVector3(pointLocation.x, pointLocation.y, pointLocation.z)

            self.augmentedRealityView.scene.rootNode.addChildNode(clone)
            oldPoints.insert([pointLocation.x, pointLocation.y, pointLocation.z], at: 0)
        }
        
        DispatchQueue.main.async {
            self.sendData()
        }
    }
  
}

class ViewController: UIViewController {

    //1. Create A Reference To Our ARSCNView In Our Storyboard Which Displays The Camera Feed
    @IBOutlet weak var augmentedRealityView: ARSCNView!
    
    //2. Create A Reference To Our ARSCNView In Our Storyboard Which Will Display The ARSession Tracking Status
    @IBOutlet weak var sessionLabelView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rawFeaturesLabel: UILabel!
    @IBOutlet var settingsConstraint: NSLayoutConstraint!
    @IBOutlet weak var threshButton: UIButton!
    
    var Feature_Label_Prefix = "Number Of Raw Feature Points Detected = "
    
    //3. Create Our ARWorld Tracking Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    //4. Create Our Session
    let augmentedRealitySession = ARSession()
    
    //5. Create A Single SCNNode Which We Will Clone
    var sphereNode: SCNNode!
    
    //--------------------
    //MARK: View LifeCycle
    //--------------------
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        generateNode()
        setupARSession()

    }
    
    override var prefersStatusBarHidden: Bool { return true }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }

    //----------------------
    //MARK: SCNNode Creation
    //----------------------
    
    @IBAction func setThresh(_ sender: Any) {
        var mean: Float = 0
        var count: Float = 0
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 0.5
        sessionConfig.timeoutIntervalForResource = 0.5
        
        for p in oldPoints {
            let x = p[0] - pos!.transform[3][0]
            let y = p[1] - pos!.transform[3][1]
            let z = p[2] - pos!.transform[3][2]
            mean = mean + (x*x + y*y + z*z).squareRoot()
            count = count + 1
            //mean[0] = mean[0] + p[0] - pos[0]
            //mean[1] = mean[1] + p[1] - pos[1]
            //mean[2] = mean[2] + p[2] - pos[2]
            //count = count + 1
        }
        
        let json: [String: Any] = ["stuff": mean / count]
        threshold = mean / count
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request10.42.0.1:8000
        //172.20.10.2
        let url = URL(string: connectURL + "/threshold")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession(configuration: sessionConfig).dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()

    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "soundName", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url)

            player.volume = magnitude

            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    /// Generates A Spherical SCNNode
    func generateNode(){
        sphereNode = SCNNode()
        let sphereGeometry = SCNSphere(radius: 0.001)
        sphereGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
        sphereNode.geometry = sphereGeometry
    }
    
    func sendData(){
        var adjusted: Array<Float> = Array()
        let sessionConfig = URLSessionConfiguration.default
        var mean: Float = 0
        var count: Float = 0
        sessionConfig.timeoutIntervalForRequest = 0.5
        sessionConfig.timeoutIntervalForResource = 0.5
        
        for p in oldPoints {
            let x = p[0] - pos!.transform[3][0]
            let y = p[1] - pos!.transform[3][1]
            let z = p[2] - pos!.transform[3][2]
            adjusted.append((x*x + y*y + z*z).squareRoot())
            //mean[0] = mean[0] + p[0] - pos[0]
            //mean[1] = mean[1] + p[1] - pos[1]
            //mean[2] = mean[2] + p[2] - pos[2]
            mean = mean + (x*x + y*y + z*z).squareRoot()
            count = count + 1
        }
        
        if (mean / count) < threshold {
            //print("Increasing")
            print(magnitude)
            magnitude = min(magnitude + increaseAmount, MAXSOUNDS)
        } else {
            //print("Decreasing")
            print(magnitude)
            magnitude = max(magnitude - increaseAmount, MINSOUNDS)
        }
        
        //print(dist)
        //print(mean[0] / count, mean[1] / count)
        
        if Date().timeIntervalSince1970 - startTime > duration {
            startTime = Date().timeIntervalSince1970
            
            self.playSound()
        }
        
        
        
        let json: [String: Any] = ["stuff": adjusted]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request10.42.0.1:8000
        //172.20.10.2
        let url = URL(string: connectURL + "/points")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession(configuration: sessionConfig).dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        

    }

    //---------------
    //MARK: ARSession
    //---------------
    
    /// Sets Up The ARSession
    func setupARSession(){
        
        //1. Set The AR Session
        augmentedRealityView.session = augmentedRealitySession
        augmentedRealityView.delegate = self
        
        configuration.planeDetection = [planeDetection(.None)]
        augmentedRealitySession.run(configuration, options: runOptions(.ResetAndRemove))
        
        self.rawFeaturesLabel.text = ""
       
        
    }
}

