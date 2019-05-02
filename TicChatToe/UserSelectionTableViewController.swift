//
//  UserSelectionTableViewController.swift
//  TicChatToe
//
//  Created by Hunter Boleman on 4/27/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit
import Parse

class UserSelectionTableViewController: UITableViewController {
    
    // Class Variables
    let debugInfo: Bool = false
    let expireTime = 20.0
    var onlineUsers: [PFObject] = [];
    var verification: [PFObject] = [];
    var queryLimit = 15
    var selectedUser = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Used for testing, acts as if a user pushed the connect button to those users
        if (PFUser.current()?.username == "hb1"){
            selectedUser = "hb2"
        }
        if (PFUser.current()?.username == "hb2"){
            selectedUser = "hb1"
        }
    }
    
    //-------------------- Utilities --------------------//
    
    // Finds if object is expired or not, and if it is it will call the garbage collector.
    func isExpired(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            print("EXPIRED")
            garbageObj(obj: obj)
            return true;
        }
        
        let storedTime = obj.createdAt as! Date;
        let expTime = storedTime.addingTimeInterval(expireTime);
        let nowTime = Date();
        
        if (debugInfo){
            print("now time: \(nowTime)")
            print("obj time: \(storedTime)")
            print("exp time: \(expTime)")
        }
        
        if (expTime < nowTime){
            if (debugInfo){print("EXPIRED")}
            garbageObj(obj: obj)
            return true
        }
        else {
            if (debugInfo){print("NOT-EXPIRED")}
            return false
        }
    }
    
    // Used for populating the tableview without disrupting it's own process (aka, it doesn't remove anything during the check)
    func canDisplay(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            print("EXPIRED")
            return false;
        }
        
        let storedTime = obj.createdAt as! Date;
        let expTime = storedTime.addingTimeInterval(expireTime);
        let nowTime = Date();
        
        if (debugInfo){
            print("now time: \(nowTime)")
            print("obj time: \(storedTime)")
            print("exp time: \(expTime)")
        }
        
        if (expTime < nowTime){
            if (debugInfo){print("EXPIRED")}
            return false
        }
        else {
            if (debugInfo){print("NOT-EXPIRED")}
            return true
        }
    }
    
    // Removed a specified object
    func garbageObj(obj: PFObject){
        obj.deleteInBackground(block: { (sucess, error) in
            if (sucess == true){
                print("Delete: TRUE")
                self.getOnlineUserList()
            }
            else {
                print("Delete: FALSE")
            }
        })
    }
    
    //-------------------- Parse Get Functions --------------------//
    
    // Refresh OnlineUserList
    func getOnlineUserList(){
        print("Get Parse Data")
        
        let query = PFQuery(className:"Users")
        query.limit = queryLimit;
        query.includeKey("user")
        query.order(byDescending: "createdAt")
        
        query.findObjectsInBackground { (messages, error) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let message = messages {
                // The find succeeded.
                self.onlineUsers = message
                print("Successfully retrieved \(message.count) posts.")
            }
            print ("reload tableView")
            self.tableView.reloadData();
        }
    }
    
    // Refresh Verification List
    func getVerificationList(){
        print("Get Parse Data")
        
        let query = PFQuery(className:"ConnectionData")
        query.limit = queryLimit;
        query.includeKey("user")
        query.order(byDescending: "createdAt")
        
        query.findObjectsInBackground { (messages, error) in
            if let error = error {
                // Log details of the failure
                print(error.localizedDescription)
            } else if let message = messages {
                // The find succeeded.
                self.verification = message
                print("Successfully retrieved \(message.count) posts.")
            }
            print ("reload tableView")
            self.tableView.reloadData();
        }
    }
    
    //-------------------- Actions --------------------//
    
    // Button to call Find Selected Users
    @IBAction func FindSelectedUserBTN(_ sender: Any) {
        FindSelectedUsers()
    }
    // Tries to find selected user using variable "selectedUser"
    func FindSelectedUsers(){
        for index in 0..<onlineUsers.count {
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as! PFUser).username
            if (isExpired(obj: singleUser) == true) {
                print("Found Selected User Offline: \(selectedUser)")
            }
            else{
                if (usr == selectedUser){
                    print("Found Selected User Online: \(selectedUser)")
                    sendVerification(str: "first_send")
                }
            }
        }
        if (onlineUsers.count <= 0){
            print("No Users Online!")
        }
    }
    
    // Button to call Set User Status Online
    @IBAction func SetUserStatusOnlineBTN(_ sender: Any) {
        SetUserStatusOnline()
    }
    // This will show other users that you are online
    func SetUserStatusOnline(){
        for index in 0..<self.onlineUsers.count {
            
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as? PFUser)
            if(usr == PFUser.current() && isExpired(obj: singleUser) == false){
                print("Found Self Unexpired")
            }
            else{
                // If status has expired, renew
                let singleUser = PFObject(className: "Users");
                singleUser["user"] = PFUser.current();
                
                singleUser.saveInBackground { (success, error) in
                    if success {
                        print("Online Status Updated")
                    } else if let error = error {
                        print("Problem saving message: \(error.localizedDescription)")
                    }
                }
            }
        }
        // If there are no statuses to trigger for loop, set status
        if (self.onlineUsers.count == 0){
            let singleUser = PFObject(className: "Users");
            singleUser["user"] = PFUser.current();
            
            singleUser.saveInBackground { (success, error) in
                if success {
                    print("Online Status Updated")
                } else if let error = error {
                    print("Problem saving message: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Button to call Refresh Parse Data
    @IBAction func RefreshParseDataBTN(_ sender: Any) {
        RefreshParseData()
    }
    // Does a combined refresh and listen
    func RefreshParseData(){
        // refresh parse data
        getOnlineUserList()
        getVerificationList()
        listenForVerification()
    }
    
    // Used for testing, doesn't work super well, but keeping it for testing anyhow.
    @IBAction func autoTester(_ sender: Any) {
        atemptToConnect()
    }
    
    //-------------------- Verification Related --------------------//
    
    // A testing function that will be replaced once we have a timer function
    func atemptToConnect(){
        self.SetUserStatusOnline()
        self.getOnlineUserList()
        self.getVerificationList()
        self.FindSelectedUsers()
        self.getOnlineUserList()
        self.getVerificationList()
        self.listenForVerification()
    }
    
    // Listen for Verification
    func listenForVerification(){
        getVerificationList()
        
        for index in 0..<self.verification.count {
            
            let singleUser = self.verification[index];
            let usr = (singleUser["user"] as? PFUser)
            let atm = (singleUser["atemptingToConnectTo"] as! String)
            let hrd = singleUser["atemptHeard"] as! Bool
            // Someone is trying to connect to me.
            if(atm == PFUser.current()?.username && isExpired(obj: singleUser) == false && hrd == false){
                print("\(usr?.username ?? "") is Atempting to Connect.")
                selectedUser = usr!.username!
                sendVerification(str: "send_heard")
                break
            }
            else if(atm == PFUser.current()?.username && isExpired(obj: singleUser) == false && hrd == true){
                // Segue to the game screen
                print("Verification Heard!")
                print("SEGUE TO GAME SCREEN!")
                self.performSegue(withIdentifier: "gameSegue", sender: nil)
            }
        }
        if (self.verification.count == 0){
            if(debugInfo){print("No Verification Data Found!")}
        }
    }
    
    
    // Sends Verification
    func sendVerification(str: String){
        // Sends first verification
        if (str == "first_send"){
            let singleUser = PFObject(className: "ConnectionData");
            singleUser["user"] = PFUser.current();
            singleUser["atemptingToConnectTo"] = selectedUser;
            singleUser["atemptHeard"] = false;
            
            singleUser.saveInBackground { (success, error) in
                if success {
                    print("First Verification Saved!")
                } else if let error = error {
                    print("Problem saving message: \(error.localizedDescription)")
                }
            }
        }
            // Sends second verification
        else if (str == "send_heard"){
            let singleUser = PFObject(className: "ConnectionData");
            singleUser["user"] = PFUser.current();
            singleUser["atemptingToConnectTo"] = selectedUser;
            singleUser["atemptHeard"] = true;
            
            singleUser.saveInBackground { (success, error) in
                if success {
                    print("Atempt Heard Saved!")
                } else if let error = error {
                    print("Problem saving message: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //-------------------- Table View Related --------------------//
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
     // Configure the cell...
     
     return cell
     }
     */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        
        // Create a new variable to store the instance of PlayerTableViewController
        let destinationVC = segue.destination as! TicTacToeTableViewController
        destinationVC.connectedUser = self.selectedUser
     }
    
 
    
}
