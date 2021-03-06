//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "CountryCodeViewController.h"
#import "OWSSearchBar.h"
#import "PhoneNumberUtil.h"
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <SignalMessaging/NSString+OWS.h>

@interface CountryCodeViewController () <OWSTableViewControllerDelegate, OWSSearchBarDelegate>

@property (nonatomic, readonly) OWSSearchBar *searchBar;

@property (nonatomic) NSArray<NSString *> *countryCodes;

@end

#pragma mark -

@implementation CountryCodeViewController

- (void)loadView
{
    [super loadView];

    self.shouldUseTheme = NO;

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"COUNTRYCODE_SELECT_TITLE", @"");

    self.countryCodes = [PhoneNumberUtil countryCodesForSearchTerm:nil];

    if (!self.isPresentedInNavigationController) {
        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                          target:self
                                                          action:@selector(dismissWasPressed:)];
    }

    [self createViews];
}

- (void)createViews
{
    // Search
    OWSSearchBar *searchBar = [OWSSearchBar new];
    _searchBar = searchBar;
    searchBar.delegate = self;
    searchBar.placeholder = NSLocalizedString(@"SEARCH_BYNAMEORNUMBER_PLACEHOLDER_TEXT", @"");
    [searchBar sizeToFit];

    self.tableView.tableHeaderView = searchBar;

    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak CountryCodeViewController *weakSelf = self;
    OWSTableSection *section = [OWSTableSection new];

    for (NSString *countryCode in self.countryCodes) {
        OWSAssert(countryCode.length > 0);
        OWSAssert([PhoneNumberUtil countryNameFromCountryCode:countryCode].length > 0);
        OWSAssert([PhoneNumberUtil callingCodeFromCountryCode:countryCode].length > 0);
        OWSAssert(![[PhoneNumberUtil callingCodeFromCountryCode:countryCode] isEqualToString:@"+0"]);

        [section addItem:[OWSTableItem
                             itemWithCustomCellBlock:^{
                                 UITableViewCell *cell = [OWSTableItem newCell];
                                 [OWSTableItem configureCell:cell];
                                 cell.textLabel.text = [PhoneNumberUtil countryNameFromCountryCode:countryCode];

                                 UILabel *countryCodeLabel = [UILabel new];
                                 countryCodeLabel.text = [PhoneNumberUtil callingCodeFromCountryCode:countryCode];
                                 countryCodeLabel.font = [UIFont ows_regularFontWithSize:16.f];
                                 countryCodeLabel.textColor = Theme.secondaryColor;
                                 [countryCodeLabel sizeToFit];
                                 cell.accessoryView = countryCodeLabel;

                                 return cell;
                             }
                             actionBlock:^{
                                 [weakSelf countryCodeWasSelected:countryCode];
                             }]];
    }

    [contents addSection:section];

    self.contents = contents;
}

- (void)countryCodeWasSelected:(NSString *)countryCode
{
    OWSAssert(countryCode.length > 0);

    NSString *callingCodeSelected = [PhoneNumberUtil callingCodeFromCountryCode:countryCode];
    NSString *countryNameSelected = [PhoneNumberUtil countryNameFromCountryCode:countryCode];
    NSString *countryCodeSelected = countryCode;
    [self.countryCodeDelegate countryCodeViewController:self
                                   didSelectCountryCode:countryCodeSelected
                                            countryName:countryNameSelected
                                            callingCode:callingCodeSelected];
    [self.searchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OWSSearchBarDelegate

- (void)searchBar:(OWSSearchBar *)searchBar textDidChange:(NSString *)text
{
    [self searchTextDidChange];
}

- (void)searchBar:(OWSSearchBar *)searchBar returnWasPressed:(NSString *)text
{
    [self searchTextDidChange];
}

- (void)searchTextDidChange
{
    NSString *searchText = [self.searchBar.text ows_stripped];

    self.countryCodes = [PhoneNumberUtil countryCodesForSearchTerm:searchText];

    [self updateTableContents];
}

#pragma mark - OWSTableViewControllerDelegate

- (void)tableViewWillBeginDragging
{
    [self.searchBar resignFirstResponder];
}

@end
