//
//  SSAliasForm.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSBaseForm.h"

@class MUDAlias;

@interface SSAliasForm : SSBaseForm

+ (instancetype) formForAlias:(MUDAlias *)alias;

@end
