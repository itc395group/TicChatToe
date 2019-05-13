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
    let expireTime = 10.0
    var onlineUsers: [PFObject] = [];
    var verification: [PFObject] = [];
    var queryLimit = 50
    var selectedUser = ""
    var atemptCounter: Int = 0;
    var segueTriggered: Bool = false;
    var runTimer: Bool = true;
    var timerCount: Int = 0;
    var timerMax: Int = 3;
    var atemptingToConnect: Bool = false;
    var nameList: [String] = [];
    var count = 0
    var tableArr: [UserSelectionTableViewCell] = [];
    var selectedIndex: Int = 0;
    var connectionType: String = ""
    var seguePlayerPiece: String = ""
    
    //Colors
    let myRed = UIColor(red:0.89, green:0.44, blue:0.31, alpha:1.0);
    let myBlue = UIColor(red:0.19, green:0.62, blue:0.79, alpha:1.0);
    let myGreen = UIColor(red:0.56, green:0.81, blue:0.48, alpha:1.0);
    
    // Outlets
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet var UserTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("IN VIEW DID LOAD")
        EarlyGarbageCollection()
        SetUserStatusOnline()
        getOnlineUserList()
        tableView.reloadData()
        
        // Sets getChatMessage to retrieve messages every x seconds
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timedFunc), userInfo: nil, repeats: true)
        
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
    
    // Runs through all datasets and will remove expired data
    func garbageCollection(){
        print("GARBAGE COLLECTING...")
        getVerificationList()
            for index in 0..<onlineUsers.count{
                isExpired(obj: onlineUsers[index])
            }
            for index in 0..<verification.count{
                isExpired(obj: verification[index])
            }
            RefreshParseData()
        print("END GARBAGE COLLECTING")
    }
    
    // Treats all data from current user as expired, and removes it
    func EarlyGarbageCollection(){
        print("EARLY GARBAGE DUMP...")
        getVerificationList()
        for index in 0..<onlineUsers.count{
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as! PFUser).username
            if(usr == PFUser.current()?.username || usr == selectedUser){
                garbageObj(obj: onlineUsers[index])
            }
        }
        for index in 0..<verification.count{
            let singleUser = self.verification[index];
            let usr = (singleUser["user"] as! PFUser).username
            if(usr == PFUser.current()?.username || usr == selectedUser){
                garbageObj(obj: onlineUsers[index])
            }
        }
        RefreshParseData()
        print("END EARLY GARBAGE DUMP")
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
                garbageCollection()
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
        for index in 0..<verification.count {
            isExpired(obj: verification[index])
        }
    }
    
    //-------------------- Actions --------------------//
    
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
    
    // Does a combined refresh and listen
    func RefreshParseData(){
        // refresh parse data
        if(segueTriggered == false){
            getOnlineUserList()
            listenForVerification()
            getVerificationList()
        }
        else{
        }
    }
    
    //-------------------- Verification Related --------------------//
    
    // This function will run the process of trying to connect with each time it is called.
    func atemptToConnect(){
        if (atemptCounter == 0){
            // Set User Status Online, then wait a while before do again
            self.SetUserStatusOnline()
        }
        else if (atemptCounter == 1){
            // Refresh Parse Data
            self.RefreshParseData()
        }
        else if (atemptCounter == 2){
            // Initiate connection to user
            self.FindSelectedUsers()
        }
        else if (atemptCounter > 2 && atemptCounter < 20){
            // Then refresh 20 times before start again.
            self.RefreshParseData()
        }
        else if (atemptCounter > 20){
            atemptingToConnect = false
        }
        atemptCounter = atemptCounter + 1;
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
                    connectFromRequest()
                    selectedUser = usr!.username!
                    sendVerification(str: "send_heard")
                    break
                }
                // Verification heard, time to segue
                else if(atm == PFUser.current()?.username && isExpired(obj: singleUser) == false && hrd == true){
                    // Segue to the game screen
                    segueTriggered = true
                    print("Verification Heard!")
                    print("SEGUE TO GAME SCREEN!")
                    
                    // Blast verification heard to help guarentee delivery
                    for index in 0...15 {
                        sendVerification(str: "send_heard")
                    }
                    
                    self.performSegue(withIdentifier: "gameSegue", sender: nil)
                    //print("SEGUE TO PLAYER SELECTION!")
                    break
                }
            }
        }
        if (self.verification.count == 0 && segueTriggered == false){
            if(debugInfo){print("No Verification Data Found!")}
        }
    }
    
    
    // Sends Verification based on argument sent to it
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
    
    // Button in the tableview cell that initiates connection
    @IBAction func connectButton(_ sender: Any) {
        //Get sender
        let button = sender as! UIButton
        // Get tag that was attached to the button
        selectedIndex = button.tag
        //Use tag to find cell information
        let cell = tableArr[button.tag]
        //Assign selected user from cell data
        selectedUser = cell.usernameLable.text!
        
        // Modify cell to display connection is occurring
        cell.userSelectionButtonOutlet.backgroundColor = myBlue;
        cell.statusLable.text = "🔄"
        connectionType = "Connecting..."
        cell.userSelectionButtonOutlet.setTitle("Connecting...", for: UIControl.State.init())
        seguePlayerPiece = "X"
        atemptingToConnect = true;
    }
    
    // Runs when a user recieves a connection request
    func connectFromRequest(){
        //Get the cell that triggered the segue by searching for the cell that contains the requestor
        var indexNum: Int = 0;
        for index in 0..<tableArr.count{
            if (tableArr[index].usernameLable.text == selectedUser){
                indexNum = index
                selectedIndex = indexNum
            }
        }
        // Get cell
        let cell = tableArr[indexNum]
        // Assign selected user from cell data
        selectedUser = cell.usernameLable.text!
        
        // Modify cell to display request is occurring
        cell.userSelectionButtonOutlet.backgroundColor = myBlue;
        cell.statusLable.text = "🔄"
        connectionType = "Requesting..."
        cell.userSelectionButtonOutlet.setTitle("Requesting...", for: UIControl.State.init())
        seguePlayerPiece = "O"
        atemptingToConnect = true;
    }
    
    // Sets Table Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        count = 0
        nameList = [];
        // Gets number by keeping track of usernames, and doesn't allow duplicates or self.
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
        // Prepares tableview cell copy
        tableArr.removeAll()
        tableArr.reserveCapacity(count + 10)
        return count
    }
    
    // Sets Table Cell Contents
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // gets a single message
        var singleMessage = onlineUsers[indexPath.row];
        var usr = (singleMessage["user"] as? PFUser)!.username;
        var selfIndex: Int = 0;
        
        // Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserSelectionTableViewCell") as! UserSelectionTableViewCell
        cell.userSelectionButtonOutlet.tag = Int(indexPath.row);
        
        // Get next user if current is self, and there is more users ahead
        if (usr == PFUser.current()?.username && (indexPath.count + 1) < (onlineUsers.count)){
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
                    // Keeps the proper connection look if connection is happening
                    if (usr == selectedUser){
                        cell.userSelectionButtonOutlet.setTitle(connectionType, for: UIControl.State.init())
                        cell.userSelectionButtonOutlet.backgroundColor = myBlue;
                        cell.statusLable.text = "🔄"
                    }
                    else {
                        cell.statusLable.text = "✅"
                    }
                    // Populate tableArr with all cells headed for tableview to there is a copy available
                    tableArr.insert(cell, at: indexPath.row)
                    let val = Int(indexPath.row)
                    tableArr[val] = cell
                    // Adds username to list to prevent duplicates
                    nameList.append(usr!)
                }
            }
        }
        return cell
    }
    
    // Logs user out and goes to login screen
    @IBAction func logoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginController")
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.window?.rootViewController = loginViewController
    }
    
    
    // Prep for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Create a new variable to store the instance of PlayerTableViewController
        let destinationVC = segue.destination as! TicTacToeViewController
        destinationVC.connectedUser = self.selectedUser
        destinationVC.playersPiece = self.seguePlayerPiece
        let dex = IndexPath(row: selectedIndex, section: 0)
        
        tableView.deselectRow(at: dex, animated: true)
    }
}
