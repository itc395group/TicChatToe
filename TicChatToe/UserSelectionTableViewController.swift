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
    var queryLimit = 15
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
    
    //-------------------- Parse Related --------------------//
    
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
            //self.tableView.reloadData();
        }
    }
    
    //-------------------- Actions --------------------//
    
    // Tries to find selected user using variable "selectedUser"
    @IBAction func FindSelectedUser(_ sender: Any) {
        for index in 0..<onlineUsers.count {
            let singleUser = self.onlineUsers[index];
            let usr = (singleUser["user"] as! PFUser).username
            if (isExpired(obj: singleUser) == true) {
                print("Found Selected User Offline: \(selectedUser)")
            }
            else{
                if (usr == selectedUser){
                    print("Found Selected User Online: \(selectedUser)")
                }
            }
        }
        if (onlineUsers.count <= 0){
            print("No Users Online!")
        }
    }
    
    // This will show other users that you are online
    @IBAction func SetUserStatusOnline(_ sender: Any) {
        let countOfMessages = self.onlineUsers.count;
        for index in 0..<countOfMessages {

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
    
    @IBAction func RefreshParseData(_ sender: Any) {
        // refresh parse data
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
