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
    let expireTime = 60.0
    var onlineUsers: [PFObject] = [];
    var queryLimit = 5
    var selectedUser = "hb1"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    //-------------------- Utilities --------------------//
    
    // Finds if object is expired or not
    func isExpired(obj: PFObject) -> Bool {
        if ((obj.createdAt) == nil){
            //print("EXPIRED")
            garbageObj(obj: obj)
            return true;
        }
        
        let storedTime = obj.createdAt as! Date;
        
        if (storedTime >= Date().addingTimeInterval(expireTime)){
            //print("EXPIRED")
            garbageObj(obj: obj)
            return true
        }
        else {
            print("not-expired")
            return false
        }
    }
    
    // Removed a specified object
    func garbageObj(obj: PFObject){
        if (isExpired(obj: obj) == true){
            
            obj.deleteInBackground(block: { (sucess, error) in
                if (sucess == true){
                    print("Delete: TRUE")
                }
                else {
                    print("Delete: FALSE")
                }
            })
        }
    }
    
    //-------------------- Parse Related --------------------//
    
    // Refresh OnlineUserList
    func getOnlineUserList(){
        print("Get Parse Data")
        
        let query = PFQuery(className:"Users")
        query.limit = queryLimit;
        query.includeKey("user")
        //query.whereKey("createdAt", lessThan: Date().addingTimeInterval(expireTime))
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
            //self.tableView.reloadData();
        }
    }
    
    //-------------------- Actions --------------------//
    
    // Tries to find selected user
    @IBAction func testUserBtn(_ sender: Any) {
        for index in 0..<onlineUsers.count {
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as! PFUser).username
            if (isExpired(obj: singleUser) == true) {
                //print("expired user: \(usr.username ?? "")")
            }
            else{
                if (usr == selectedUser){
                    print("online user: \(selectedUser)")
                }
            }
        }
    }
    
    // This will show other users that you are online
    @IBAction func testSetOnlineBtn(_ sender: Any) {
        // This snippit will reset the "dead man's switch"
        //var objID = "";
        //var upd = Date();
        let countOfMessages = self.onlineUsers.count;
        print("countmsg: \(countOfMessages)")
        //var singleUsrObjID = ""
        for index in 0..<countOfMessages {
            // gets a single message
            let singleUser = self.onlineUsers[index];
            //print(singleUser)
            let usr = (singleUser["user"] as? PFUser)
//            if (singleUser["objectId"] != nil){
//            singleUsrObjID = (singleUser["objectId"]) as! String
//            upd = (singleUser.createdAt as! Date)
//            }
            //print("current: \(PFUser.current())")
            //print("usr: \(usr)")
            if(usr == PFUser.current() && isExpired(obj: singleUser) == false){
                print("Found unexpires self user obj! testsetbtnonline")
            }
            else{
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
        if (countOfMessages == 0){
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
    
    @IBAction func testRefreshData(_ sender: Any) {
        getOnlineUserList()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
