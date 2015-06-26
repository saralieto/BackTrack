//
//  NMAYearCollectionViewController.m
//  NostalgiaMusic
//
//  Created by Sara Lieto on 6/25/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "NMAYearCollectionViewController.h"
#import "NMAYearCollectionViewCell.h"

static NSInteger const earliestYear = 1980;
static NSInteger const latestYear =  2014;

@interface NMAYearCollectionViewController ()
@property (strong, nonatomic) NSMutableArray *years;

@end

@implementation NMAYearCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView.delegate self];
    self.collectionView.dataSource = self;
    self.collectionView.clipsToBounds = YES;
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([NMAYearCollectionViewCell class]) bundle:nil]
forCellWithReuseIdentifier:@"YearCell"];
    self.flow = [[UICollectionViewFlowLayout alloc]init];
    self.flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.collectionView setCollectionViewLayout:self.flow];
    [self setUpYears];
    }

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSIndexPath *defaultYear = [NSIndexPath indexPathForItem:34 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:defaultYear atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

-(void)setUpYears{
    self.years = [[NSMutableArray alloc] init];
    for(int i = 0; i < (latestYear - earliestYear + 1); i++){
        NSString *yearForCell = [NSString stringWithFormat:@"%ld", earliestYear + i];
        [self.years addObject:yearForCell];
    }
    
}
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
  //  [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.years.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(70, 40);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
   NMAYearCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YearCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    NSString *year = self.years[indexPath.row];
    cell.year.text = year;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"indexPath - %lu",indexPath.row);
    NSString *currentYear = [self.years objectAtIndex:indexPath.row];
     NSLog(@"Current Year %@", currentYear);
    [self.delegate didSelectYear:currentYear];
}

#pragma mark UICollectionViewDelegate

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
