//
//  CSLInventoryVC.m
//  CS108iOSClient
//
//  Created by Lam Ka Shun on 15/9/2018.
//  Copyright © 2018 Convergence Systems Limited. All rights reserved.
//

#import "CSLInventoryVC.h"

@interface CSLInventoryVC ()

@end

@implementation CSLInventoryVC

@synthesize btnInventory;
@synthesize lbTagRate;
@synthesize lbUniqueTagRate;
@synthesize lbTagCount;
@synthesize tblTagList;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tabBarController setTitle:@"Inventory"];
    
    tblTagList.dataSource=self;
    tblTagList.delegate=self;
    [tblTagList reloadData];
    
    [CSLRfidAppEngine sharedAppEngine].reader.delegate = self;
    [CSLRfidAppEngine sharedAppEngine].reader.readerDelegate=self;
    
    tblTagList.layer.borderWidth=1.0f;
    tblTagList.layer.borderColor=[UIColor lightGrayColor].CGColor;
    tblTagList.layer.cornerRadius=5.0f;
    
    //timer event on updating UI
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(refreshTagListing)
                                   userInfo:nil
                                    repeats:YES];
}

//Selector for timer event on updating UI
- (void)refreshTagListing {
    if ([CSLRfidAppEngine sharedAppEngine].reader.connectStatus==TAG_OPERATIONS)
    {
        //update table
        [tblTagList reloadData];
        
        //update inventory count
        lbTagCount.text=[NSString stringWithFormat: @"%ld", (long)[tblTagList numberOfRowsInSection:0]];
        
        //update tag rate
        NSLog(@"Total Tag Count: %ld, Unique Tag Coun t: %ld, time elapsed: %ld", ((long)[CSLRfidAppEngine sharedAppEngine].reader.rangingTagCount), ((long)[CSLRfidAppEngine sharedAppEngine].reader.uniqueTagCount), (long)[[NSDate date] timeIntervalSinceDate:tagRangingStartTime]);
        lbTagRate.text = [NSString stringWithFormat: @"%ld", ((long)[CSLRfidAppEngine sharedAppEngine].reader.rangingTagCount)];
        lbUniqueTagRate.text = [NSString stringWithFormat: @"%ld", ((long)[CSLRfidAppEngine sharedAppEngine].reader.uniqueTagCount)];
        [CSLRfidAppEngine sharedAppEngine].reader.rangingTagCount =0;
        [CSLRfidAppEngine sharedAppEngine].reader.uniqueTagCount =0;
        
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tabBarController setTitle:@"Inventory"];
    
    //clear UI
    lbTagRate.text=@"0";
    lbTagCount.text=@"0";
    [CSLRfidAppEngine sharedAppEngine].reader.filteredBuffer=nil;
    [tblTagList reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    //stop inventory if it is still running
    if (btnInventory.enabled)
    {
        if ([[btnInventory currentTitle] isEqualToString:@"STOP"])
            [btnInventory sendActionsForControlEvents:UIControlEventTouchUpInside];

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnInventoryPressed:(id)sender {
    if ([CSLRfidAppEngine sharedAppEngine].reader.connectStatus==CONNECTED && [[btnInventory currentTitle] isEqualToString:@"START"])
    {
        btnInventory.enabled=false;
        //reader configurations before inventory
        
        //clear UI
        lbTagRate.text=@"0";
        lbTagCount.text=@"0";
        [CSLRfidAppEngine sharedAppEngine].reader.filteredBuffer=nil;
        [tblTagList reloadData];
        
        
        //set inventory configurations

        
        [[CSLRfidAppEngine sharedAppEngine].reader setPower:[CSLRfidAppEngine sharedAppEngine].settings.power / 10];
        [[CSLRfidAppEngine sharedAppEngine].reader setAntennaCycle:COMMAND_ANTCYCLE_CONTINUOUS];
        [[CSLRfidAppEngine sharedAppEngine].reader setAntennaDwell:0];
        [[CSLRfidAppEngine sharedAppEngine].reader setLinkProfile:[CSLRfidAppEngine sharedAppEngine].settings.linkProfile];
        [[CSLRfidAppEngine sharedAppEngine].reader setQueryConfigurations:([CSLRfidAppEngine sharedAppEngine].settings.target == ToggleAB ? A : [CSLRfidAppEngine sharedAppEngine].settings.target) querySession:[CSLRfidAppEngine sharedAppEngine].settings.session querySelect:ALL];
        [[CSLRfidAppEngine sharedAppEngine].reader selectAlgorithmParameter:[CSLRfidAppEngine sharedAppEngine].settings.algorithm];
        [[CSLRfidAppEngine sharedAppEngine].reader setInventoryAlgorithmParameters0:[CSLRfidAppEngine sharedAppEngine].settings.QValue maximumQ:15 minimumQ:0 ThresholdMultiplier:4];
        [[CSLRfidAppEngine sharedAppEngine].reader setInventoryAlgorithmParameters1:0];
        [[CSLRfidAppEngine sharedAppEngine].reader setInventoryAlgorithmParameters2:([CSLRfidAppEngine sharedAppEngine].settings.target == ToggleAB ? true : false) RunTillZero:false];
        [[CSLRfidAppEngine sharedAppEngine].reader setInventoryConfigurations:[CSLRfidAppEngine sharedAppEngine].settings.algorithm MatchRepeats:0 tagSelect:0 disableInventory:0 tagRead:0 crcErrorRead:1 QTMode:0 tagDelay:0 inventoryMode:1];
        
        
        //start inventory
        tagRangingStartTime=[NSDate date];
        [[CSLRfidAppEngine sharedAppEngine].reader startInventory];
        [btnInventory setTitle:@"STOP" forState:UIControlStateNormal];
        btnInventory.enabled=true;
    }
    else if ([[btnInventory currentTitle] isEqualToString:@"STOP"])
    {
        if([[CSLRfidAppEngine sharedAppEngine].reader stopInventory])
        {
            [btnInventory setTitle:@"START" forState:UIControlStateNormal];
            btnInventory.enabled=true;
        }
        else
        {
            [btnInventory setTitle:@"STOP" forState:UIControlStateNormal];
            btnInventory.enabled=true;
        }
    }
    
    
}

- (void) didInterfaceChangeConnectStatus: (CSLBleInterface *) sender {
    
}

- (void) didReceiveTagResponsePacket: (CSLBleReader *) sender tagReceived:(CSLBleTag*)tag {
    //[tagListing reloadData];
}

- (void) didTriggerKeyChangedState: (CSLBleReader *) sender keyState:(BOOL)state {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (btnInventory.enabled)
        {
            if (state) {
                if ([[btnInventory currentTitle] isEqualToString:@"START"])
                    [btnInventory sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
            else {
                if ([[btnInventory currentTitle] isEqualToString:@"STOP"])
                    [btnInventory sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[CSLRfidAppEngine sharedAppEngine].reader.filteredBuffer count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* epc=((CSLBleTag*)[[CSLRfidAppEngine sharedAppEngine].reader.filteredBuffer objectAtIndex:indexPath.row]).EPC;
    UITableViewCell * cell=[tableView dequeueReusableCellWithIdentifier:epc];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:epc];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Arial" size:14];
    cell.textLabel.text = [NSString stringWithFormat:@"%5d \u25CF %@ \u25CF RSSI: %d", (int)(indexPath.row + 1), epc, (int)((CSLBleTag*)[[CSLRfidAppEngine sharedAppEngine].reader.filteredBuffer objectAtIndex:indexPath.row]).rssi];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}




@end


