pageextension 80009 "PC Purchase Order List Ext" extends "Purchase Order List"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Request Approval,Print/Send,Order,Release,Posting,Navigate,Pet Culture',
                                 ENA = 'New,Process,Report,Request Approval,Print/Send,Order,Release,Posting,Navigate,Pet Culture';

    layout
    {
        addafter("Buy-from Vendor Name")
        {
            field("Order Type"; rec."Order Type")
            {
                ApplicationArea = All;
            }
            field("Fulfilo ASN Status"; rec."Fulfilo ASN Status")
            {
                ApplicationArea = All;
            }
            field("EDI Status"; rec."EDI Status")
            {
                ApplicationArea = All;
                StyleExpr = Styler1;
            }
         }
    }
    actions
    {
        addafter("P&osting")
        {
            Group("Pet Culture")
            {
                Action(Msg1)
                {
                    ApplicationArea = all;
                    Caption = 'Import/Export Purchase Orders';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Imports/Exports Purchase Orders';
                    trigger OnAction()
                    var
                        CU:Codeunit "PC Import Export Routines";
                    begin
                        Case Strmenu('Import Purchase Orders,Export Purchase Orders') of
                            0:Exit;
                            1:CU.Build_Import_PO();
                            else    
                                CU.Build_Export_PO();
                        End;
                    end;            
                } 
                Action(Msg2)
                {
                    ApplicationArea = all;
                    Caption = 'Supplier Rebates';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Supplier Brand Rebate Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "PC Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(0,'');
                        Pg.RunModal();     
                    end;  
                }    
                Action(MsgA)
                {
                    ApplicationArea = all;
                    Caption = 'PO Line Disc %';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'PO Line Disc % Maintenance';
                    trigger OnAction()
                    var
                        Pg:Page "PC Supplier Brand Rebates";
                    begin
                        Pg.Set_Page_Mode(3,'');
                        Pg.RunModal();     
                    end;  
                }    
                Action(MsgB)
                {
                    ApplicationArea = all;
                    Caption = 'Cost Analysis';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Product Cost Analysis';
                    RunObject = PAGE "PC Cost Analysis";
                }    
                action(Msg3)
                {
                    ApplicationArea = all;
                    Caption = 'Manage Fulfilio ASN';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Manages Fulfilio ASN Status';
                    trigger OnAction()
                    var
                        cu:Codeunit "PC Fulfilio Routines";
                        Corr:Record "PC Purchase Corrections";
                        Pg:Page "PC Purchase Corrections";
                    begin
                        If (rec."Order Type" = rec."Order Type"::FulFilo) AND (rec.Status = rec.Status::Released) then
                        begin 
                            Case StrMenu('Create Fulfilio ASN,Update Fulfilio ASN,Cancel Fulfilio ASN,Check Fulfilio ASN Status',1) of
                                1:
                                begin
                                    If rec."Fulfilo ASN Status"  in [rec."Fulfilo ASN Status"::" ",rec."Fulfilo ASN Status"::Cancelled] then
                                    begin
                                        If Confirm(StrSubstNo('Create Fulfilio ASN For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Create_ASN(Rec) then
                                                Message('Fulfilio ASN Creation Successfull')
                                            else
                                                Message('Fulfilio ASN Creation UnSuccessfull');
                                        End;
                                    end    
                                    else
                                        message('Invalid Fufilio ASN Status for ASN Creation');            
                                end;
                                2:
                                begin
                                    If rec."Fulfilo ASN Status" = rec."Fulfilo ASN Status"::Pending then
                                    begin                            
                                        If Confirm(StrSubstNo('Update Fulfilio ASN For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Update_ASN(rec) then
                                                Message('Fulfilio ASN Update Successfull')
                                            else
                                                Message('Fulfilio ASN Update UnSuccessfull');
                                        End;
                                    end    
                                    else
                                       message('Fulfilio Update ASN is only valid for Fulfilio ASN Status Pending');            
                               end;
                               3:
                                begin
                                    If rec."Fulfilo ASN Status" = rec."Fulfilo ASN Status"::Pending then
                                    begin
                                        If Confirm(StrSubstNo('Cancel Fulfilio ASN For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Update_ASN(Rec) then
                                                Message('Fulfilio ASN Cancel Successfull')
                                            else
                                                Message('Fulfilio ASN Cancel UnSuccessfull');
                                        End;
                                    end    
                                    else
                                        message('Fulfilio Cancel ASN is only valid for Fulfilio ASN Status Pending');            
                                end;
                                4:
                                begin
                                    If rec."Fulfilo ASN Status" <> rec."Fulfilo ASN Status"::" " then
                                    begin                 
                                        If Confirm(StrSubstNo('Check Fulfilio ASN Status For Location %1 Now?',rec."Location Code"),True) then
                                        Begin
                                            If Cu.Get_ASN_Order_Status(Rec,True) then
                                            begin
                                                If rec."Fulfilo ASN Status" = rec."Fulfilo ASN Status"::Completed then
                                                begin
                                                    Corr.reset;
                                                    Corr.Setrange(User,USERID);
                                                    If Corr.findset then
                                                    begin
                                                        Pg.SetTableView(Corr);
                                                        Pg.RunModal();
                                                    end;
                                                end    
                                                else      
                                                     Message('Check Fulfilio ASN Status Successfull');
                                            end    
                                            else
                                                Message('Check Fulfilio ASN UnSuccessfull');
                                        End;
                                    end    
                                    else
                                        message('Fulfilio ASN Status Blank is Invalid for Fulfilio Check ASN Status');            
                                end;
                            end
                        end    
                        else
                            message('Only Valid For Released Orders of Type Fulfilio');
                    end;                
                }    
                Action(Msg4)
                {
                    ApplicationArea = all;
                    Caption = 'Purchase Order Exceptions';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    ToolTip = 'Purchase Order Exceptions';
                    trigger OnAction()
                    var
                        pg:page "PC Purch. Order Exceptions";
                    begin
                        Case Strmenu('Show Fulfilio Exceptions,Show EDI Exceptions',1) of
                            1:pg.Set_Display_Mode(true);       
                            2:pg.Set_Display_Mode(false); 
                        end;
                        pg.RunModal();        
                    end;
                }
                Action(MsgD)
                {
                    ApplicationArea = all;
                    Caption = 'Simulate EDI Processing';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    trigger OnAction()
                    var
                        CU:Codeunit "PC EDI Routines";
                    begin
                        If Confirm('Simulate EDI Processing Now',True) then
                        Begin
                            Cu.Simulate_EDI_Processing(false);
                            Cu.Process_EDI_Transaction_Documents();
                            Cu.Simulate_EDI_Processing(True);
                        end;
                    end;    
                }
                Action(MsgE)
                {
                    ApplicationArea = all;
                    Caption = 'EDI Transaction Log';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    trigger OnAction()
                    var
                        PG:Page "PC EDI Execution Log";
                    begin
                        PG.RunModal();
                    end;
                }
                Action(MsgF)
                {
                    ApplicationArea = all;
                    Caption = 'ASN Tracking Log';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category10;
                    trigger OnAction()
                    var
                        PG:Page "PC ASN Tracking";
                    begin
                        PG.RunModal();
                    end;
                }
            }    
        }
    }
    trigger OnAfterGetRecord()
    Begin
        Styler1 := 'strong';
        if rec."EDI Status" = Rec."EDI Status"::"EDI Vendor" then 
            Styler1 := 'favorable';    
    end;
    var
        Styler1:text;

}    