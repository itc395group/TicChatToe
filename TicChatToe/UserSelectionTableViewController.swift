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
    var queryLimit = 25
    var selectedUser = ""
    var auto: Int = 0;
    var segueTriggered: Bool = false;
    var runTimer: Bool = true;
    var timerCount: Int = 0;
    var timerMax: Int = 3;
    var atemptingToConnect: Bool = false;
    var nameList: [String] = [];
    var count = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Used for testing, acts as if a user pushed the connect button to those users
        if (PFUser.current()?.username == "hb1"){
            selectedUser = "hb4"
        }
        if (PFUser.current()?.username == "hb2"){
            selectedUser = "hb1"
        }
        
        SetUserStatusOnline()
        getOnlineUserList()
        tableView.reloadData()
        
        // Sets getChatMessage to retrieve messages every x seconds
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timedFunc), userInfo: nil, repeats: true)
        
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
        // Freeze timer while removing object
        let realTimerState = runTimer;
        runTimer = false;
        
        obj.deleteInBackground(block: { (sucess, error) in
            if (sucess == true){
                print("Delete: TRUE")
                //self.getOnlineUserList()
            }
            else {
                print("Delete: FALSE")
            }
        })
        
        // set timer to previous state
        runTimer = realTimerState
    }
    
    //-------------------- Main Timer Function --------------------//
    
    // The logic that will run on a timer
    @objc func timedFunc() {
        // forced timer off when segue occurs
        if (segueTriggered == true){
            runTimer = false;
        }
        
        // Run when timer is "active"
        if (runTimer == true){
            print("in active timed func")
            // When looking for user, run connection process every second
            if (atemptingToConnect == true){
                atemptToConnect();
            }
            
            // Refresh player list every 3 seconds
            if (timerCount >= timerMax && atemptingToConnect == false){
                RefreshParseData()
                SetUserStatusOnline()
            }
            
            // Used to create actions on a delay
            if (timerCount >= timerMax){timerCount = 0}
            timerCount = timerCount + 1;
        }
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
        
        for index in 0..<verification.count {
            isExpired(obj: verification[index])
        }
        
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
        print("In user status set online")
        var found: Bool = false;
        for index in 0..<self.onlineUsers.count {
            
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as? PFUser)
            if(usr == PFUser.current() && isExpired(obj: singleUser) == false){
                print("Found Self Unexpired")
                found = true;
            }
        }
        if (found == false){
        // If status has expired, renew
        let singleUser = PFObject(className: "Users");
        singleUser["user"] = PFUser.current();
        }
        
        // If there are no statuses to trigger for loop, set status
        if (self.onlineUsers.count == 0 || found == false){
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
        if(segueTriggered == false){
            getOnlineUserList()
            listenForVerification()
        }
    }
    
    // Used for testing, doesn't work super well, but keeping it for testing anyhow.
    @IBAction func autoTester(_ sender: Any) {
        runTimer = true;
        atemptingToConnect = true;
    }
    
    //-------------------- Verification Related --------------------//
    
    // A testing function that will be replaced once we have a timer function
    func atemptToConnect(){
        if (auto == 0){
            // Set User Status Online, then wait a while before do again
            self.SetUserStatusOnline()
        }
        else if (auto == 1){
            // Refresh Parse Data
            self.RefreshParseData()
        }
        else if (auto == 2){
            // Initiate connection to user
            self.FindSelectedUsers()
        }
        else if (auto > 2 && auto < 20){
            // Then refresh like 20 times before start again.
            self.RefreshParseData()
        }
        auto = auto + 1;
    }
    
    // Listen for Verification
    func listenForVerification(){
        getVerificationList()
        
        for index in 0..<self.verification.count {
            if (segueTriggered == false){
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
                    segueTriggered = true
                    print("Verification Heard!")
                    print("SEGUE TO GAME SCREEN!")
                    
                    for index in 0...15 {
                        sendVerification(str: "send_heard")
                    }
                    
                    self.performSegue(withIdentifier: "gameSegue", sender: nil)
                    break
                }
            }
        }
        if (self.verification.count == 0 && segueTriggered == false){
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
    
    // Sets Table Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        count = 0
        nameList = [];
        //nameList.append(PFUser.current()!.username!)
        
        if (onlineUsers.count > 0){
            for index in 0..<onlineUsers.count{
                // gets a single message
                let singleMessage = onlineUsers[index];
                let usr = (singleMessage["user"] as? PFUser)!.username;
                
                // Only increment count if Can Display, Not a Repeat, & Not Self
                if (canDisplay(obj: singleMessage) && nameList.contains(usr!) == false && usr != PFUser.current()?.username){
                    count = count + 1
                    nameList.append(usr!)
                }
                else {
                    if (nameList.contains(usr!) == false){
                        nameList.append(usr!)
                    }
                }
            }
        }
        else{
            count = 0
        }
        return count
    }
    
    // Sets Table Cell Contents
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //nameList = [];
        //nameList.append(PFUser.current()!.username!)
        
        // gets a single message
        var singleMessage = onlineUsers[indexPath.row];
        var usr = (singleMessage["user"] as? PFUser)!.username;
        var selfIndex: Int = 0;
        
        // Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserSelectionTableViewCell") as! UserSelectionTableViewCell
        
        if (usr == PFUser.current()?.username){
            selfIndex = indexPath.count + 1
            // gets a single message
            singleMessage = onlineUsers[selfIndex];
            usr = (singleMessage["user"] as? PFUser)!.username;
        }
        else {
            selfIndex = indexPath.count;
        }

        if (count > 0){
            for index in 0..<nameList.count {
                if (nameList[index] != PFUser.current()?.username){
                    cell.usernameLable.text = nameList[index]
                    cell.statusLable.text = "✅"
                    nameList.append(usr!)
                    //cell.isHidden = false;
                }
            }
        }
        else {
            cell.usernameLable.text = "false"
            cell.statusLable.text = "false"
            
            //cell.isHidden = true;
        }
        return cell
    }
    
    
    @IBAction func logoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginController")
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.window?.rootViewController = loginViewController
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
        let destinationVC = segue.destination as! TicTacToeViewController
        destinationVC.connectedUser = self.selectedUser
    }
    
    
    
}
