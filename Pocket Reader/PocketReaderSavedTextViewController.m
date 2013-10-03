//
//  PocketReaderSavedTextViewController.m
//  Pocket Reader
//
//  Created by Gabriel Borges Fernandes on 9/17/13.
//  Copyright (c) 2013 Gabriel Borges Fernandes. All rights reserved.
//

#import "PocketReaderSavedTextViewController.h"
#import "PocketReaderSavedTextCell.h"

@interface PocketReaderSavedTextViewController ()

@end

@implementation NSMutableArray(Plist)

-(BOOL)writeToPlistFile:(NSString*)filename{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    BOOL didWriteSuccessfull = [data writeToFile:path atomically:YES];
    return didWriteSuccessfull;
}

+(NSMutableArray*)readFromPlistFile:(NSString*)filename{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSData * data = [NSData dataWithContentsOfFile:path];
    return  [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end //needs to be set for implementation

@implementation PocketReaderSavedTextViewController

@synthesize savedText;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.savedText = [NSMutableArray readFromPlistFile:@"SavedText.plist"];
    if (self.savedText == nil) {
        self.savedText = [NSMutableArray
                          arrayWithObjects:
                          [NSArray arrayWithObjects:
                           NSLocalizedString(@"Title of future text",nil),
                           NSLocalizedString(@"Subtitle of  future texts",nil),
                           NSLocalizedString(@"Contents of text",nil),nil],
                          nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTestNotification:)
                                                 name:@"AddToHistory"
                                               object:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) receiveTestNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"AddToHistory"]){
        NSString *received = notification.object;
        [self.savedText addObject:[NSArray arrayWithObjects:[received substringWithRange:NSMakeRange(0, 10)], [received substringWithRange:NSMakeRange(11, 30)], received, nil]];
        [self.tableView reloadData];
    }
}


-(void) viewDidDisappear:(BOOL)animated {
    BOOL deuCerto = [self.savedText writeToPlistFile:@"SavedText.plist"];
    NSLog(deuCerto ? @"Escreveu no arquivo" : @"nao escreveu no arquivo");
}

-(void) viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.savedText count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        [self.savedText removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"savedTextCell";
    PocketReaderSavedTextCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[PocketReaderSavedTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    // Configure the cell...
    cell.cellTitleLabel.text = [[self.savedText objectAtIndex:indexPath.row] objectAtIndex:0];
    cell.cellSubTitleLabel.text = [[self.savedText objectAtIndex:indexPath.row] objectAtIndex:1];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

 // In a story board-based application, you will often want to do a little preparation before navigation
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"%@ , %@", [segue identifier], [[segue destinationViewController] class]);
    PocketReaderShowTextViewController *showViewController = [segue destinationViewController];
    NSLog(@"prapara para segue");
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    [showViewController setTitleOfNavigationBar:[[self.savedText objectAtIndex:path.item] objectAtIndex:0]];
    [showViewController setStringOnTextView:[[self.savedText objectAtIndex:path.item] objectAtIndex:2]];
    NSLog(@"do segue das invejosas");
}


@end


