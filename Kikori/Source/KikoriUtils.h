//
//  Kikori.h
//  Kikori
//
//  Created by eugene on 11/4/16.
//  Copyright © 2016 Eugene Ovchynnykov. All rights reserved.
//

@import Foundation;

@interface NSURLSessionConfiguration(Kikori)
+ (void) enableKikoriForDefaultSession:(BOOL)enable;
@end

@interface NSMutableURLRequest(Kikori)
+ (void) enableSavingHTTPBody:(BOOL)enable;
@end


