//
//  ViewController.m
//  SpeechToText
//
//  Created by Huy Hoang  on 6/29/16.
//  Copyright © 2016 ntq-solution. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
#import "UIImage+animatedGIF.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"

@interface ViewController () {
    // UI
    __weak IBOutlet UIButton *speakButton;
    __weak IBOutlet UIImageView *animationImageView;
    __weak IBOutlet UITextView *resultTextView;
    
    // Speech recognize
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    SFSpeechURLRecognitionRequest *urlRequest;
    
    // Record speech using audio Engine
    AVAudioInputNode *inputNode;
    AVAudioEngine *audioEngine;
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // just add border for text view
    resultTextView.layer.borderWidth = 1.0;
    resultTextView.layer.borderColor = [UIColor grayColor].CGColor;
    resultTextView.layer.masksToBounds = YES;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
    audioEngine = [[AVAudioEngine alloc] init];
    
    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
    
    
    for (NSLocale *locate in [SFSpeechRecognizer supportedLocales]) {
        NSLog(@"%@", [locate localizedStringForCountryCode:locate.countryCode]);
    }
    // Check Authorization Status
    // Make sure you add "Privacy - Microphone Usage Description" key and reason in Info.plist to request micro permison
    // And "NSSpeechRecognitionUsageDescription" key for requesting Speech recognize permison
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        
        /*
         The callback may not be called on the main thread. Add an
         operation to the main queue to update the record button's state.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusAuthorized: {
                    speakButton.enabled = YES;
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusDenied: {
                    speakButton.enabled = NO;
                    resultTextView.text = @"User denied access to speech recognition";
                }
                case SFSpeechRecognizerAuthorizationStatusRestricted: {
                    speakButton.enabled = NO;
                    resultTextView.text = @"User denied access to speech recognition";
                }
                case SFSpeechRecognizerAuthorizationStatusNotDetermined: {
                    speakButton.enabled = NO;
                    resultTextView.text = @"User denied access to speech recognition";
                }
            }
        });
        
    }];
}

// Transcript from a file
- (void)transcriptExampleFromAFile {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"checkFile" withExtension:@"m4a"];
    urlRequest = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:urlRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (result != nil) {
            NSString *text = result.bestTranscription.formattedString;
            resultTextView.text = text;
        }
        else {
            NSLog(@"Error, %@", error.description);
        }
    }];
}

// recording
- (void)startRecording {
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"recording_animate" withExtension:@"gif"];
    animationImageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    animationImageView.hidden = NO;
    [speakButton setImage:[UIImage imageNamed:@"voice_contest_recording"] forState:UIControlStateNormal];
    
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [session setActive:TRUE withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    inputNode = audioEngine.inputNode;

    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    recognitionRequest.shouldReportPartialResults = NO;
    recognitionRequest.detectMultipleUtterances = YES;
    
    AVAudioFormat *format = [inputNode outputFormatForBus:0];
    
    [inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [audioEngine prepare];
    NSError *error1;
    [audioEngine startAndReturnError:&error1];
    NSLog(@"%@", error1.description);
    
}


- (IBAction)speakTap:(id)sender {
    if (audioEngine.isRunning) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        recognitionTask =[speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (result != nil) {
                NSString *transcriptText = result.bestTranscription.formattedString;
                resultTextView.text = transcriptText;
            }
            else {
                [audioEngine stop];;
                recognitionTask = nil;
                recognitionRequest = nil;
            }
        }];
        // make sure you release tap on bus else your app will crash the second time you record.
        [inputNode removeTapOnBus:0];
        
        [audioEngine stop];
        [recognitionRequest endAudio];
        [speakButton setImage:[UIImage imageNamed:@"voice_contest"] forState:UIControlStateNormal];
        animationImageView.hidden = YES;
        
    }
    else {
        [self startRecording];
    }
}


@end
