Group Project - README Template
===

# Tic Chat Toe

## Table of Contents
1. [Overview](#Overview)
1. [Product Spec](#Product-Spec)
1. [Wireframes](#Wireframes)
2. [Schema](#Schema)

## Overview
### Description
[Description of your app]

### App Evaluation
[Evaluation of your app across the following attributes]
- **Category:**
- **Mobile:**
- **Story:**
- **Market:**
- **Habit:**
- **Scope:**

## Product Spec

### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* -[X] Login Func
* -[ ] Logout Func
* -[X] UI
* -[ ] Have Online User List
* -[ ] Tic Tac Toe
* -[ ] Tic Tac Toe Data Stuff
* -[X] Establish Connection Between Users
* -[ ] Function that runs on timer
* ...

The below gif demos the login, UI, and Data connection between users.
<img src='https://i.imgur.com/GWuhauu.gif' title='Video Walkthrough' width='' alt='Video Walkthrough' />

**Optional Nice-to-have Stories**

* -Profile Pic
* -Score Board
* -Friend System
* -Leader Board
* * -Have Garbage Collection
* - seperate registration screen

### 2. Screen Archetypes

* Login Screen
   * User can login
   * ...
* Menu
   * List of people online to play against
   * Tap on which player to connect to
   * Random button
   * Have a win/loss ratio
   * ...
* Tic Tac Toe Screen
   * Main Screen of Game, assumming connection worked
   * Chat Message Bar with deticated area for chat window
   * ...
### 3. Navigation

**Tab Navigation** (Tab to Screen)

* Choose Player Screen
* Friends Tab
* 

**Flow Navigation** (Screen to Screen)

* Login Screen
   * Login or register
   * ...
* Choose player
    * tic tac toe
    * stats
    * friends
* Tic Tac Toe
   * 
   * ...

## Wireframes
[Add picture of your hand sketched wireframes in this section]
<img src="https://i.imgur.com/2XWdyjS.png" width=600>

### [BONUS] Digital Wireframes & Mockups

### [BONUS] Interactive Prototype

### Models

#### Users
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the user post (default field) |
   | user          | Pointer to User| stores the PFUser data |
   | profileImage (optional)  | File     | users profile image |
   | createdAt     | DateTime | date when post is created (default field) |
   | updatedAt     | DateTime | date when post is last updated (default field) |
   | friends (optional) | Array of User Objects | keeps a list of friends |
   | gameWin       | Int      | how many times a user has won |
   | gameLose      | Int      | how many times a user has lost |
   
   #### Chat
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the user post (default field) |
   | createdAt     | DateTime | date when post is created (default field) |
   | user          | Pointer to User| message author |
   | text          | String    | message contents |
   
   #### GameData
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the user post (default field) |
   | createdAt     | DateTime | date when post is created (default field)|
   | updatedAt     | DateTime | date when post is last updated (default field), used as deadman switch for online status |
   | playerO       | Parse Pointer to User | stores which player is using the “O” character |
   | playerX       | Parse Pointer to User | stores which player is using the “X” character |
   | whosTurn      | String   | stores an “X” or “O” that specifies which players turn it is |
   | turnCount     | Int      | specifies which turn is being taken. Counts up. |
   | turnData      | String   | allows the turn choice to be sent |

   #### ConnectionData
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the user post (default field) |
   | createdAt     | DateTime | date when post is created (default field) |
   | updatedAt     | DateTime | date when post is last updated (default field) |
   | atemptingToConnectTo | Parse Pointer to User | stores the user one wishes to connect to |
   | user          | Parse Pointer to User | the user who is attempting the connection |
   | atemptHeard   | Bool     | stores a flag if a user has seen a connection that is trying to reach them. |

   
   #### Optional: Scoreboard
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | objectId      | String   | unique id for the user post (default field) |
   | createdAt     | DateTime | date when post is created (default field) |
   | updatedAt     | DateTime | date when post is last updated (default field) |  
   | winCount      | Int      | stores games won |
   | loseCount     | Int      | stores games lost |
   | lastPlayed    | DateTime | Stores when the user last played a game |

### Networking
- [Add list of network requests by screen ]
- [Create basic snippets for each Parse network request]
- [OPTIONAL: List endpoints if using existing API such as Yelp]

#### List of network requests by screen
   - User Selection Screen
       - (Read/GET) Query all posts where updatedAt is within X time, aka not expired
         ```swift
         let query = PFQuery(className:"Users")
         query.whereKey("updatedAt", greaterThan: Date().addingTimeInterval(expireTime))
         query.order(byDescending: "updatedAt")
         query.findObjectsInBackground { (posts: [PFObject]?, error: Error?) in
            if let error = error { 
               print(error.localizedDescription)
            } else if let posts = posts {
               print("Successfully retrieved \(posts.count) posts.")
           // TODO: Do something with posts...
            }
         }
         ```
       - (Update/PUT) Update the UpdatedAt portion of user Obj
         ```swift
          // This snippit will reset the "dead man's switch"
      
             var objID = "";
             let countOfMessages = self.Messages.count;
        
            for index in 0..<countOfMessages {
                // gets a single message
                let Message = self.Messages[index];
                let usr = (Message["user"] as? PFUser)
                let id = (Message["objectId"])
                
                if(usr == PFUser.current()){
                    objID = id as! String;
                }
            }
        
            query.getObjectInBackground(withId: objID) { (obj, error) in
                if error != nil {
                    print(error)
                }
                else{
                    // Updates UpdatedAt
                    obj?.saveInBackground()
                }
            }
         ```
       - (Read/GET) Query data posts for Data Connection
         ```swift
                let query = PFQuery(className:"ConnectionData")
                query.addDescendingOrder("createdAt")
                query.limit = queryLimit
                query.includeKey("user")
                query.whereKey("updatedAt", greaterThan: Date().addingTimeInterval(expireTime))
            
                query.findObjectsInBackground { (messages, error) in
                    if let error = error {
                        // Log details of the failure
                        print(error.localizedDescription)
                    } else if let messages = messages {
                        // The find succeeded.
                        self.Messages = messages
                        print("Successfully retrieved \(messages.count) posts.")
                    }
                }
                print ("reload tableView")
                self.tableView.reloadData();
         ```
       - (Create/POST) Create a Data Connection Post
         ```swift
                Message["user"] = PFUser.current();
                if (sawAtempt == true){
                    Message["atemptHeard"] = true
                }
                else {
                    Message["atemptHeard"] = false
                }
                Message["atemptingToConnectTo"] = otherUser
                Message["user"] = PFUser.current()
                    Message.saveInBackground { (success, error) in
                        if success {
                            print("The message was saved!")
                            //self.chatMessageField.text = "";
                        } else if let error = error {
                            print("Problem saving message: \(error.localizedDescription)")
                        }
                    }
         ```
   - Tic Tac Toe Screen
       - (Read/GET) Query data posts for chat messages
         ```swift
                let query = PFQuery(className:"chat")
                query.addDescendingOrder("createdAt")
                query.limit = queryLimit
                query.includeKey("user")
            
                query.findObjectsInBackground { (messages, error) in
                    if let error = error {
                        // Log details of the failure
                        print(error.localizedDescription)
                    } else if let messages = messages {
                        // The find succeeded.
                        self.Messages = messages
                        print("Successfully retrieved \(messages.count) posts.")
                    }
                }
                print ("reload tableView")
                self.tableView.reloadData();
            ```
       - (Create/POST) Create a new chat message
         ```swift
                let Message = PFObject(className: "chat")
                Message["text"] = chatMessageField.text!
            
                    Message["user"] = PFUser.current();
                    Message.saveInBackground { (success, error) in
                        if success {
                            print("The message was saved!")
                            //self.chatMessageField.text = "";
                        } else if let error = error {
                            print("Problem saving message: \(error.localizedDescription)")
                        }
                    }
         ```
       - (Read/GET) Query data posts for Tic Tac Toe Data
         ```swift
                let query = PFQuery(className:"data")
                query.addDescendingOrder("createdAt")
                query.limit = queryLimit
                query.includeKey("user")
        
                query.findObjectsInBackground { (messages, error) in
                if let error = error {
                    // Log details of the failure
                    print(error.localizedDescription)
                } else if let messages = messages {
                    // The find succeeded.
                    self.Messages = messages
                    print("Successfully retrieved \(messages.count) posts.")
                }
                }
                print ("reload tableView")
                self.tableView.reloadData();
         ```
       - (Create/POST) Create a Tic Tac Toe Data post
         ```swift
            let Message = PFObject(className: "data")
            
            if (playerO == "" || playerX == ""){
            Message["playerO"] = PFUser.current
            Message["playerX"] = otherUser
            }
            
            Message["playerO"] = playerO
            Message["playerX"] = playerX
            Message["text"] = whosTurn();
            Message["text"] = turnCount
            Message["text"] = turnExport(); // Returns something like T2X for
            // Top row second col fill with X.
            Message["user"] = PFUser.current();
                Message.saveInBackground { (success, error) in
                    if success {
                        print("The message was saved!")
                        //self.chatMessageField.text = "";
                    } else if let error = error {
                        print("Problem saving message: \(error.localizedDescription)")
                    }
                }
         ```
       - ScoreBoard - Optional, will fill out if atempting to complete
