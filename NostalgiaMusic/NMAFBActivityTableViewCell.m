//
//  NMAFBActivityTableViewCell.m
//  NostalgiaMusic
//
//  Created by Eric Peterson on 7/7/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "NMAFBActivityTableViewCell.h"
#import "NMAFBLike.h"
#import "NMAFBComment.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+NMAColors.h"
#import "UIFont+NMAFonts.h"

@implementation NMAFBActivityTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.collapsed = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    self.messageLabel.textColor = [UIColor NMA_almostBlack];
    [self.likesButton setTitleColor:[UIColor NMA_darkGray] forState:UIControlStateNormal];
    [self.commentsButton setTitleColor:[UIColor NMA_darkGray] forState:UIControlStateNormal];
}

- (void)toggleCellState {
    self.collapsed = !self.collapsed;
    int messageLineCount = self.collapsed ? 2 : 0;
    self.messageLabel.numberOfLines = messageLineCount;
    [self configureCell];
}

- (void)configureCell {
    if (!self.fbActivity) {
        return;
    }
    
    if (self.fbActivity.timeString) {
        self.timeLabel.text = self.fbActivity.timeString;
    }
    
    if (self.fbActivity.message && self.fbActivity.likes && self.fbActivity.comments) {
        [self constructFullPost:self.fbActivity collapsed:self.collapsed];
        NSString *likeCountText = [@(self.fbActivity.likes.count) stringValue];
        [self.likesButton setTitle:likeCountText forState:UIControlStateNormal];
        NSString *commentCountText = [@(self.fbActivity.comments.count) stringValue];
        [self.commentsButton setTitle:commentCountText forState:UIControlStateNormal];
        [self.messageLabel sizeToFit];
    }
    
    self.collapseImageConstraint.priority = 1;
    
    //check for image
    if (self.fbActivity.imagePath) {
        NSURL *imageURL = [NSURL URLWithString:self.fbActivity.imagePath];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *postImage = [UIImage imageWithData:imageData];
        [self setImageViewDimensions:postImage];
        [self.postImageView setImage:postImage];
        [self layoutIfNeeded];
    } else {
        self.collapseImageConstraint.priority = 999;
    }
    
    //Add a shadow to the bottom of the message view
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.messageView.bounds];
    self.messageView.layer.masksToBounds = NO;
    self.messageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.messageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    self.messageView.layer.shadowOpacity = 0.5f;
    self.messageView.layer.shadowPath = shadowPath.CGPath;
}

- (void)setImageViewDimensions:(UIImage *)targetImage {
    float heightToWidthRatio = targetImage.size.height / targetImage.size.width;
    float newViewHeight = heightToWidthRatio * CGRectGetWidth(self.postImageView.frame);
    self.imageHeightConstraint.constant = newViewHeight;
}

- (void)constructFullPost:(NMAFBActivity *)fbActivity collapsed:(BOOL)collapsed {
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:fbActivity.message];
    NSAttributedString *attributedEmpty = [[NSAttributedString alloc] initWithString:@""];
    if (collapsed) {
        self.continueLabel.text = @"...Continue Reading";
        self.collapseContinueToToolsConstraint.priority = 999;
        self.collapseMessageToCreditsConstraint.priority = 1;
    } else {
        self.continueLabel.attributedText = attributedEmpty;
        self.likeCreditsLabel.attributedText = [self constructLikeCredits:fbActivity];
        self.commentThreadLabel.attributedText = [self constructCommentThread:fbActivity];
        self.collapseContinueToToolsConstraint.priority = 1;
        self.collapseMessageToCreditsConstraint.priority = 999;
    }
}

- (NSAttributedString *)constructLikeCredits:(NMAFBActivity *)fbActivity {
    NSInteger likeLimit = 6;
    NSMutableAttributedString *likeCreditString = [[NSMutableAttributedString alloc] initWithString:@""];
    if (fbActivity.likes.count == 0) {
        //there are no likes, do we remind them
    } else if (fbActivity.likes.count == 1) {
        NMAFBLike *like = fbActivity.likes[0];
        [self appendLike:like to:likeCreditString index:0 limit:1 lastCommaSpacer:3];
        
        NSAttributedString *attributedEnd = [[NSAttributedString alloc] initWithString:@" likes this post."];
        [likeCreditString appendAttributedString:attributedEnd];
        
    } else if (fbActivity.likes.count > likeLimit) {
        for (NSInteger likeIndex = 0; likeIndex < likeLimit; likeIndex++ ) {
            NMAFBLike *like = fbActivity.likes[likeIndex];
            [self appendLike:like to:likeCreditString index:likeIndex limit:likeLimit lastCommaSpacer:1];
        }
        NSInteger remainingLikes = fbActivity.likes.count - likeLimit;
        NSString *peopleOrPerson = remainingLikes > 1 ? @"people" : @"person";
        NSString *likeOrLikes = remainingLikes > 1 ? @"like" : @"likes";
        NSString *creditEnd = [NSString stringWithFormat:@"and %td other %@ %@ this post.", remainingLikes, peopleOrPerson, likeOrLikes];
        NSAttributedString *attributedCreditEnd = [[NSAttributedString alloc] initWithString:creditEnd];
        [likeCreditString appendAttributedString:attributedCreditEnd];
        
    } else {
        for (NSInteger likeIndex = 0; likeIndex < fbActivity.likes.count - 1; likeIndex++ ) {
            NMAFBLike *like = fbActivity.likes[likeIndex];
            [self appendLike:like to:likeCreditString index:likeIndex limit:fbActivity.likes.count lastCommaSpacer:2];
        }
        NSAttributedString *attributedAnd = [[NSAttributedString alloc] initWithString:@"and "];
        [likeCreditString appendAttributedString:attributedAnd];
        NMAFBLike *finalLike = fbActivity.likes[fbActivity.likes.count - 1];
        NSAttributedString *attributedFinalLike = [self boldedString:finalLike.likerName];
        [likeCreditString appendAttributedString:attributedFinalLike];
        NSAttributedString *attributedEnd = [[NSAttributedString alloc] initWithString:@" like this post."];
        [likeCreditString appendAttributedString:attributedEnd];
    }
    
    return likeCreditString;
}

- (NSAttributedString *)constructCommentThread:(NMAFBActivity *)fbActivity {
    NSMutableAttributedString *commentThreadString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    for (NMAFBComment *comment in fbActivity.comments) {
        NSAttributedString *attributedName = [self boldedString:comment.commenterName];
        [commentThreadString appendAttributedString:attributedName];
        NSAttributedString *attributedSpacer = [[NSAttributedString alloc] initWithString:@": "];
        [commentThreadString appendAttributedString:attributedSpacer];
        NSAttributedString *attribuedComment = [[NSAttributedString alloc] initWithString:comment.message];
        [commentThreadString appendAttributedString:attribuedComment];
        NSAttributedString *attributedNewline = [[NSAttributedString alloc] initWithString:@"\n"];
        [commentThreadString appendAttributedString:attributedNewline];
    }
    
    return commentThreadString;
}

- (void)appendLike:(NMAFBLike *)like
                to:(NSMutableAttributedString *)likeCreditString
             index:(NSInteger)likeIndex
             limit:(NSInteger)likeLimit
   lastCommaSpacer:(NSInteger)lastCommaSpacer {
    NSAttributedString *boldedString = [self boldedString:like.likerName];
    [likeCreditString appendAttributedString:boldedString];
    NSString *spacing = likeIndex + lastCommaSpacer < likeLimit ? @", " : @" ";
    NSAttributedString *attributedSpacing = [[NSAttributedString alloc] initWithString:spacing];
    [likeCreditString appendAttributedString:attributedSpacing];
}

- (NSAttributedString *)boldedString:(NSString *)stringToBold {
    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:stringToBold];
    NSRange boldRange = NSMakeRange(0, stringToBold.length);
    
    [attributedName beginEditing];
    [attributedName addAttribute:NSFontAttributeName value:[UIFont NMA_proximaNovaBoldWithSize:15] range:boldRange];
    [attributedName endEditing];
    
    return (NSAttributedString *)attributedName;
}

@end
