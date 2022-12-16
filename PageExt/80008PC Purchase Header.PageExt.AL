pageextension 80008 "PC Purchase Header Ext" extends "Purchase Order"
{
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approve,Release,Posting,Prepare,Order,Request Approval,Print/Send,Navigate,Pet Culture',
                                 ENA = 'New,Process,Report,Approve,Release,Posting,Prepare,Order,Request Approval,Print/Send,Navigate,Pet Culture';

    layout
    {
        addafter(Status)
        {
            field("Order Type"; rec."Order Type")
            {
                ApplicationArea = All;
            }
            field("Fulfilo ASN Status"; rec."Fulfilo ASN Status")
            {
                ApplicationArea = All;
                Style = Strong;
                Enabled = flg;
            }
            field("EDI Status"; rec."EDI Status")
            {
                ApplicationArea = All;
                Style = Strong;
                Enabled = flg;
            }
            Field("Fulfilo Order ID";rec."Fulfilo Order ID")
            {
                ApplicationArea = All;
                Style = Strong;
                Enabled = flg;
                Caption = 'Fufilio Record Id';
            }
            Field("Fulfilo External Id";rec."Fulfilo External Id")
            {
                ApplicationArea = All;
                Style = Strong;
                Enabled = flg;
                Caption = 'Fufilio ASN No';
            }
            Field("Fulfilo Identifier";Rec."Fulfilo Identifier")
            {
                ApplicationArea = All;
                Style = Strong;
                Enabled = flg;
                Caption = 'Fufilio Identifier';
            }
            Group("EDI Tracking")
            {
                field("EDI Response Received";rec."EDI Response Received")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Enabled = flg;
                }
                field("EDI Dispatch Received";Rec."EDI Dispatch Received")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Enabled = flg;
                }
                field("EDI Invoice Received";rec."EDI Invoice Received")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Enabled = flg;
                }
                field("EDI Transaction Status";rec."EDI Transaction Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
        addafter("Requested Receipt Date")
        {
            field("Requested Receipt Time";rec."Requested Receipt Time")
            {
                ApplicationArea = All;
            }
        }
     }
    actions
    {
        addafter(Approval)
        {
            action(Approve2)
            {
                ApplicationArea = Suite;
                Caption = 'Approve,Create ASN & Email';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Approve the requested changes.';
                Visible = OpenApprovalEntriesExistForCurrUser;
                trigger OnAction()
                begin
                    Approve_ASN_Email(false);
                end;
            }
        }
        addafter("Request Approval")
        {
            action(RMg1)
            {
                ApplicationArea = all;
                Caption = 'Approve,Create ASN & Email';
                Promoted = true;
                Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
                Image = SendApprovalRequest;
                PromotedIsBig = true;
                PromotedCategory = Category9;
                trigger OnAction()
                begin
                    Approve_ASN_Email(True);        
                end;
            }
        }
        addafter(Invoices)
        {
            Group("Pet Culture")
            {
                action(Mg1)
                {
                    ApplicationArea = all;
                    Caption = 'Manage Fulfilio ASN';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category12;
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
                action(EDI)
                {
                    ApplicationArea = all;
                    Caption = 'Manage EDI Functions';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category12;
                    ToolTip = 'Manages EDI Functions';
                    trigger OnAction()
                    var
                        Cu:Codeunit "PC EDI Routines";
                        Excp:record "PC EDI Exception Messages";
                    begin
                        Case Strmenu('Send Original PO,Send Replace PO,Send Cancel PO',1) of
                            1: 
                            begin
                                If (Rec."Fulfilo ASN Status" = Rec."Fulfilo ASN Status"::" ") AND
                                   (Rec."EDI Transaction Status" = Rec."EDI Transaction Status"::" ") AND 
                                   (Rec.Status = Rec.Status::Released) AND (Rec."EDI Status" = Rec."EDI Status"::"EDI Vendor") then
                                begin
                                    if Confirm('Send Original PO via EDI Now',True) then
                                    begin
                                        Cu.Build_EDI_Purchase_Order(rec,'ORIGINAL');
                                        CU.EDI_Execution_Transaction_Log(rec,0);
                                    end;    
                                end 
                                else If confirm('Purchase Order is not in the correct state to raise Original via EDI .. send Regardless',false) then
                                begin
                                    Cu.Build_EDI_Purchase_Order(rec,'ORIGINAL');
                                    CU.EDI_Execution_Transaction_Log(rec,0);
                                end;    
                                
                            end;    
                            2:
                            Begin
                                If  (Rec."EDI Transaction Status" = Rec."EDI Transaction Status"::ORIGINAL) AND 
                                    (Rec.Status = Rec.Status::Released)AND (Rec."EDI Status" = Rec."EDI Status"::"EDI Vendor") then
                                begin
                                    if Confirm('Send Replace PO via EDI Now',True) then
                                    begin
                                        Excp.reset;
                                        Excp.SetRange("Purchase Order No.",Rec."No.");
                                        If Excp.FindSet() then Excp.DeleteAll();        
                                        Cu.Build_EDI_Purchase_Order(rec,'REPLACE');
                                        CU.EDI_Execution_Transaction_Log(rec,0);
                                    end;    
                                end 
                                else If confirm('Purchase Order is not in the correct state to raise Replace via EDI .. send Regardless',false) then
                                begin
                                    Cu.Build_EDI_Purchase_Order(rec,'REPLACE');
                                    CU.EDI_Execution_Transaction_Log(rec,0);
                                end;    
                            end;
                            3:
                            Begin
                                If (Rec."EDI Transaction Status" > 0) AND 
                                   (Rec.Status = Rec.Status::Released) AND (Rec."EDI Status" = Rec."EDI Status"::"EDI Vendor") then
                                begin
                                    if Confirm('Send Replace PO via EDI Now',True) then
                                        Cu.Build_EDI_Purchase_Order(rec,'CANCEL');
                                end 
                                else 
                                    Message('Purchase Order is not in the correct state to raise CANCEL via EDI');    
                            end;
                        end;
                    end;
                }    
                action(Msg2)
                {
                    ApplicationArea = All;
                    Caption = 'Access Fulfilio/EDI Status';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category12;
                    trigger OnAction()
                    begin
                        Case StrMenu('Enabled Access,Disable Access',1) of
                            1:Flg := true;
                            2:Clear(Flg);
                        end;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }
    local procedure Approve_ASN_Email(Mode:Boolean)
    var
        cu:Codeunit "PC Fulfilio Routines";
        Cuex:codeunit "PC Shopify Routines";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Ven:record Vendor;
        Loc:record Location;
        PurchHdr:record "Purchase Header";
        PurchLine:array[2] of record "Purchase Line";
    begin
        If (Rec.Status <> Rec.Status::Released) and 
           (Rec."Order Type" = Rec."Order Type"::Fulfilo) and
           (Rec."EDI Status" = Rec."EDI Status"::"Non EDI Vendor") then
        begin
            If Confirm('Approve,Create ASN & Email PO Now',True) then
            begin
                If Ven.get(rec."Buy-from Vendor No.") then
                begin
                    If Not Ven."Operations E-Mail".Contains('@') then
                    begin
                        Message('Vendor Operations Email Address is missing or is invalid .. Correct and Retry');
                        exit;
                    end;
                end 
                else
                begin
                    Message('Buy-From Vendor is missing .. Correct and Retry');
                    exit;
                end;
                if Not Loc.get(rec."Location Code") then
                begin
                    Message('Location code is not defined .. Correct and Retry');
                    Exit;
                end;
                If Loc."Fulfilo Warehouse ID" = 0 then
                begin
                    Message('Fulfilio Warehouse ID is invalid .. correct and retry');
                    Exit;
                end;
                If (rec."Requested Receipt Date" = 0D)
                    AND (rec."Promised Receipt Date" = 0D) then
                begin
                    Message('Requested/Promised Receipt Dates must be defined .. correct and retry');
                    exit;
                end;    
                PurchLine[1].reset;
                PurchLine[1].SetCurrentKey("Line No.");
                PurchLine[1].Setrange("Document Type",Rec."Document Type"::Order);
                PurchLine[1].Setrange("Document No.",Rec."No.");
                PurchLine[1].Setrange(Type,PurchLine[1].Type::Item);
                PurchLine[1].Setfilter("No.",'<>FREIGHT');
                PurchLine[1].SetFilter(Quantity,'>0');
                If Not Purchline[1].Findset then
                begin
                    Message('Purchase order containes no item lines .. correct and retry');
                    exit;
                end;
                Purchline[2].CopyFilters(Purchline[1]);
                repeat
                    Purchline[2].Setrange("No.",Purchline[1]."No.");
                    If Purchline[2].Count > 1 then
                    begin
                        message('%1 is repeated on PO\Only Unique SKU No. are allowed',Purchline[1]."No.");
                        exit;
                    end;    
                until PurchLine[1].next = 0;
                If Mode then
                begin
                    if ApprovalsMgmt.CheckPurchaseApprovalPossible(Rec) then
                        ApprovalsMgmt.OnSendPurchaseDocForApproval(Rec);
                end 
                else
                    ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                PurchHdr.get(Rec."Document Type",Rec."No.");
                If PurchHdr.Status = PurchHdr.Status::Released then
                begin    
                    if PurchHdr."Fulfilo ASN Status"  in [PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::Cancelled] then
                        If Not Cu.Create_ASN(PurchHdr) then
                        begin
                            Message('Fulfilio ASN Creation was unSuccessfull .. emailing is not possible');
                            exit;
                        end;
                    if Cuex.Send_PO_Email(PurchHdr) then
                        Message('PO has been emailed successfully to ' + Ven."Operations E-Mail")
                    else
                        Message('Emailing has failed for ' + Ven."Operations E-Mail");    
                end;       
            end;
        end    
        else 
            Message('Order is not in the correct state for this action .. Aborting');
    end;

    trigger OnOpenPage()
    var
        ApprovalsMgmt:Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
        Dummy:Boolean;
    begin
        Clear(flg);
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        WorkflowWebhookMgt.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, Dummy);
    end;
    var
        flg:Boolean;
        OpenApprovalEntriesExistForCurrUser:Boolean;
        OpenApprovalEntriesExist:Boolean;
        CanRequestApprovalForFlow:Boolean;

}