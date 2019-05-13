//
//  UserSelectionCell.swift
//  TicChatToe
//
//  Created by Ryan on 5/8/19.
//  Copyright © 2019 Ricky Bernal. All rights reserved.
//

import UIKit

class UserSelectionCell: UITableViewCell {

    // Outlets
    @IBOutlet weak var playernameLabel: UILabel!
    @IBOutlet weak var checkmarkLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
