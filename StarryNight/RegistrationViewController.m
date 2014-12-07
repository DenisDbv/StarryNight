//
//  RegistrationViewController.m
//  StarryNight
//
//  Created by Denis Dubov on 25.11.14.
//  Copyright (c) 2014 brandmill. All rights reserved.
//

#import "RegistrationViewController.h"
#import "WTReTextField/WTReTextField.h"
#import "UIView+Helpers.h"

#import <CoreLocation/CoreLocation.h>
#import "SPGooglePlacesAutocompleteQuery.h"
#import "SPGooglePlacesAutocompletePlace.h"

#import "Reachability.h"

#import "SkyViewController.h"

@interface RegistrationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet WTReTextField *dateField;
@property (weak, nonatomic) IBOutlet UITextField *placeField;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@property (nonatomic, strong) UITableView *autocompleteTableView;

@end

@implementation RegistrationViewController  {
    SPGooglePlacesAutocompleteQuery *searchQuery;
    NSArray *foundPlacesArray;
    CLLocationCoordinate2D selectCoordinate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    self.navigationController.navigationBarHidden = YES;
    
    searchQuery = [[SPGooglePlacesAutocompleteQuery alloc] init];
    //searchQuery.radius = 1000.0;
    
    self.nameField.layer.borderWidth = 1;
    self.nameField.layer.borderColor = [UIColor colorWithRed:103.0/255.0 green:113.0/255.0 blue:172.0/255.0 alpha:1.0].CGColor;
    self.nameField.font = [UIFont fontWithName:@"Opium" size:21.5];
    
    self.dateField.layer.borderWidth = 1;
    self.dateField.layer.borderColor = [UIColor colorWithRed:103.0/255.0 green:113.0/255.0 blue:172.0/255.0 alpha:1.0].CGColor;
    self.dateField.pattern = @"^(3[0-1]|[1-2][0-9]|(?:0)[1-9])(?:\\.)(1[0-2]|(?:0)[1-9])(?:\\.)[1-9][0-9]{3}$";
    self.dateField.font = [UIFont fontWithName:@"Opium" size:21.5];
    
    self.placeField.layer.borderWidth = 1;
    self.placeField.layer.borderColor = [UIColor colorWithRed:103.0/255.0 green:113.0/255.0 blue:172.0/255.0 alpha:1.0].CGColor;
    [self.placeField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    self.placeField.font = [UIFont fontWithName:@"Opium" size:21.5];
    
    self.autocompleteTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.placeField.left, self.placeField.bottom, self.placeField.width, 60) style:UITableViewStylePlain];
    self.autocompleteTableView.scrollEnabled = NO;
    self.autocompleteTableView.dataSource = self;
    self.autocompleteTableView.delegate = self;
    self.autocompleteTableView.alpha = 0;
    self.autocompleteTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.autocompleteTableView];
    
    [self checkInternetConnection];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void) viewWillAppear:(BOOL)animated   {
    
    self.nameField.text = @"";
    self.dateField.text = @"";
    self.placeField.text = @"";
    [UIView animateWithDuration:0.2 animations:^{
        self.confirmButton.alpha = 1;
        [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
            self.placeField.alpha = 1;
            [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionTransitionNone animations:^{
                self.dateField.alpha = 1;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionTransitionNone animations:^{
                    self.nameField.alpha = 1;
                } completion:^(BOOL finished) {
                    
                }];
            }];
        } completion:^(BOOL finished) {
            //
        }];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

-(void) viewWillDisappear:(BOOL)animated    {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event    {
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    CGFloat delta = 130;
    if(self.nameField.isFirstResponder || self.dateField.isFirstResponder)  {
        [UIView animateWithDuration:0.3 animations:^{
            self.nameField.top = 246 - delta;
            self.dateField.top = 319 - delta;
            self.placeField.top = 392 - delta;
            self.autocompleteTableView.top = self.placeField.bottom;
        }];
    } else  {
        [UIView animateWithDuration:0.3 animations:^{
            self.nameField.alpha = 0;
            self.dateField.alpha = 0;
            self.placeField.top = 246 - delta;
            self.autocompleteTableView.top = self.placeField.bottom;
        }];
    }
    
    self.confirmButton.hidden = YES;
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        self.nameField.top = 246;
        self.dateField.top = 319;
        self.placeField.top = 392;
        self.nameField.alpha = 1;
        self.dateField.alpha = 1;
    }];
    
    self.confirmButton.hidden = NO;
    self.autocompleteTableView.alpha = 0;
}

-(void) checkInternetConnection {
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    if(reach.currentReachabilityStatus == NotReachable)    {
        NSLog(@"Internet access denied!");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Нет доступа к интернету" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.tag == 3) {
        CGFloat delta = 130;
        [UIView animateWithDuration:0.3 animations:^{
            self.nameField.alpha = 0;
            self.dateField.alpha = 0;
            self.placeField.top = 246 - delta;
            self.autocompleteTableView.top = self.placeField.bottom;
        }];
        
        [self checkInternetConnection];
    }
}

- (void)textFieldEditingChanged:(UITextField *)textField
{
    if (textField.tag == 3) {
        searchQuery.input = textField.text;
        [searchQuery fetchPlaces:^(NSArray *places, NSError *error) {
            if (error) {
                NSLog(@"Could not fetch Places (%@)", error);
            } else {
                foundPlacesArray = places;
                
                if(foundPlacesArray.count > 0)  {
                    self.autocompleteTableView.alpha = 1.0;
                    [self.autocompleteTableView reloadData];
                } else  {
                    self.autocompleteTableView.alpha = 0.0;
                    [self.autocompleteTableView reloadData];
                }
            }
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1; //foundPlacesArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath  {
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AutocompleteCell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)   {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:@"Mayonez-LightItalic" size:13.0];
    }
    
    cell.textLabel.text = @"";
    cell.textLabel.textColor = [UIColor colorWithRed:103.0/255.0 green:113.0/255.0 blue:172.0/255.0 alpha:1.0];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    if(foundPlacesArray.count > 0)  {
        SPGooglePlacesAutocompletePlace *foundPlace = foundPlacesArray[0]; //indexPath.row];
        if (foundPlace) {
            [foundPlace resolveToPlacemark:^(CLPlacemark *place, NSString *addressString, NSError *error) {
                NSLog(@"Placemark: %@", place);
                if(place.country.length > 0)    {
                    cell.textLabel.text = [@"" stringByAppendingString:place.country];
                    cell.textLabel.text = [cell.textLabel.text stringByAppendingString:@" "];
                }
                if(place.locality.length > 0)   {
                    cell.textLabel.text = [cell.textLabel.text stringByAppendingString:place.locality];
                }
            }];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SPGooglePlacesAutocompletePlace *foundPlace = foundPlacesArray[indexPath.row];
    self.placeField.text = foundPlace.name;
    
    if (foundPlace) {
        [foundPlace resolveToPlacemark:^(CLPlacemark *place, NSString *addressString, NSError *error) {
            CLLocation *location = place.location;
            selectCoordinate = location.coordinate;
            NSLog(@"%@",[NSString stringWithFormat:@"%f, %f", selectCoordinate.latitude, selectCoordinate.longitude]);
        }];
    }
    
    self.autocompleteTableView.alpha = 0;
    [self.placeField resignFirstResponder];
}

- (IBAction)onConfirm:(id)sender {
    if(self.nameField.text.length == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Введите своё имя" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSArray *strings = [self.dateField.text componentsSeparatedByString:@"."];
    if(self.dateField.text.length == 0 || strings.count < 3) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Введите дату своего рождения" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    if(self.placeField.text.length == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Введите место своего рождения" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.nameField.text forKey:@"NAME"];
    [userDefaults setObject:self.dateField.text forKey:@"DATE"];
    [userDefaults setObject:self.placeField.text forKey:@"PLACE"];
    [userDefaults setObject:[NSNumber numberWithDouble:selectCoordinate.latitude] forKey:@"PLACE_LAT"];
    [userDefaults setObject:[NSNumber numberWithDouble:selectCoordinate.longitude] forKey:@"PLACE_LONG"];
    [userDefaults synchronize];
    
    SkyViewController *skyVC = [[SkyViewController alloc] initWithNibName:@"SkyViewController" bundle:nil];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.nameField.alpha = 0;
        [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
            self.dateField.alpha = 0;
            [UIView animateWithDuration:0.4 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
                self.placeField.alpha = 0;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
                    self.confirmButton.alpha = 0;
                } completion:^(BOOL finished) {
                    [self.navigationController pushViewController:skyVC animated:NO];
                }];
            }];
        } completion:^(BOOL finished) {
            //
        }];
    }];
}

@end
