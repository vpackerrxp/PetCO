page 80030 "PC Order Reconciliation"
{
    Caption = 'Order Reconcilliation';
    PageType = Worksheet;
    SourceTable = "PC Order Reconciliations";
    InsertAllowed = false;
    DeleteAllowed = true;
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(content)
        {
            Group(Filters)
            {
                field("From Order Date Filter"; OrdDateFilter[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If OrdDateFilter[2] <> 0D then
                            if OrdDateFilter[1] > OrdDateFilter[2] then Clear(OrdDateFilter[1]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdDateFilter[1]);
                        SetFilters();
                    end;
                }
                field("To Order Date Filter"; OrdDateFilter[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If OrdDateFilter[1] <> 0D then
                            if OrdDateFilter[2] < OrdDateFilter[1] then Clear(OrdDateFilter[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdDateFilter[2]);
                        SetFilters();
                    end;
                }
                field("Order Types Filter";OrdType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(OrdType);
                        SetFilters();
                    end;
                }
                field("Payment Gate Way Filter";Payments)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Payments);
                        SetFilters();
                    end;
                }
                field("Apply Status Filter";ApplyStat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(ApplyStat);
                        SetFilters();
                    end;
                }
                field("CL";'Clear All Filters')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = False;
                    trigger OnDrillDown()
                    begin
                        Clear(OrdDateFilter);
                        Clear(Payments);
                        Clear(ApplyStat);
                        Clear(OrdType);
                        Setfilters();
                    end;
                }
            }
            Group(Processing)
            {
                Field("Receipt Posting Date";PstDate)
                {
                    Caption = 'Receipt Posting Date';
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        CurrPage.update(false);
                    end;    
                }
                field("imp";'Import&Process Data')
                {
                    ApplicationArea = All;
                    StyleExpr = 'strongaccent';
                    ShowCaption = False;
                    trigger OnDrillDown()
                    var
                        cu:Codeunit "PC Import Export Routines";
                    begin
                        If MFee <> '' then
                            Cu.Import_Reconcilliation(Mfee)
                        else
                            Message('Please provide the Merchant Fee Account');    
                        CurrPage.update(false);
                    end;
                }
                field("Merchant Fee Account";MFee)
                {
                    ApplicationArea = All;
                    StyleExpr = 'strong';
                    TableRelation = "G/L Account";
                }
                field("exp";'Export Data')
                {
                    ApplicationArea = All;
                    StyleExpr = 'favorable';
                    ShowCaption = False;
                    ToolTip = 'Exports Unapplied Records';
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Import Export Routines";
                    begin
                        If (Payments <> Payments::All) AND (PSTDate <> 0D)
                        AND (ApplyStat = ApplyStat::UnApplied) Then
                        begin 
                            If Confirm(StrsubStno('Export Displayed Records Using Posting Date %1 And Payment Type %2 Now'
                                                ,PSTDate,Payments),True) then
                            begin
                                Cu.Export_Reconcilliation_Data(rec,PSTDate);
                                Clear(PSTDate);
                                SetFilters();
                            end 
                        end       
                        else
                            Message('Ensure Pay Type filter/Apply Type Filter and Posting Date are defined correctly');
                        CurrPage.update(false);
                    end;
                }
                Group("Balances")
                {
                    field("Bal";'Check Entry Balances')
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        ShowCaption = False;
                        ToolTip = 'Display Out Of Balance Entries';
                        trigger OnDrillDown()
                        Begin
                            Clear(OrdDateFilter);
                            Clear(Payments);
                            Clear(ApplyStat);
                            Clear(OrdType);
                            Check_GL_Balance();
                            Rec.MarkedOnly(True);
                            Currpage.update(false);
                        end;       
                    }
                }
            }
            repeater(General)
            {
                field("Shopify Order ID"; Rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                    Visible = False;
                }
                field("Shopify Display ID"; Rec."Shopify Display ID")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Order ID';
                }
                field("Shopify Order Type"; Rec."Shopify Order Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Cu:Codeunit "PC Shopify Routines"; 
                        Ordhdr:record "PC Shopify Order Header";

                    begin
                        If (Rec."Shopify Order Type" = Rec."Shopify Order Type"::Refund) And 
                            (Get_BC_Document() = '') AND (Rec."Extra Refund Count" = 0) then
                            If Confirm('Check and Process Refund Document Now?',True) then
                            begin
                                Ordhdr.Reset;
                                Ordhdr.Setrange("Order Status",Ordhdr."Order Status"::Closed);
                                Ordhdr.Setrange("Order Type",Ordhdr."Order Type"::Invoice);
                                Ordhdr.Setrange("Shopify Order ID",Rec."Shopify Order ID");
                                If Ordhdr.findset then
                                begin
                                    Clear(Ordhdr."Refunds Checked");
                                    Ordhdr.Modify(false);     
                                    Cu.Process_Refunds(Rec."Shopify Order No");
                                    Ordhdr.Setrange("Order Status",Ordhdr."Order Status"::Open);
                                    Ordhdr.Setrange("Order Type",Ordhdr."Order Type"::CreditMemo);
                                    If Ordhdr.findset then
                                        Cu.Process_Orders(false,Ordhdr.ID);
                                    CurrPage.update(false);
                                end;
                            end;   
                    end;
                }
                field("Shopify Order No"; Rec."Shopify Order No")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        OrdHdr:record "PC Shopify Order Header";
                        PG:Page "PC Shopify Orders";
                        GLEnt:Record "G/L Entry";
                        GLSetup:Record "General Ledger Setup";
                        GLPag:Page "General Ledger Entries";
                    begin
                        Case Strmenu('Show Document,Show GL Entries',1) of
                            1:
                            Begin        
                                OrdHdr.reset;
                                OrdHdr.Setrange("Shopify Order No.",Rec."Shopify Order No");
                                OrdHdr.Setrange("Order Type",Rec."Shopify Order Type");
                                If OrdHdr.findset then
                                begin
                                    PG.SetTableView(OrdHdr);
                                    Pg.Run;
                                end
                                else If Confirm('Order not found in downloaded Shopify orders Open Invoice Instead?',True) then
                                begin
                                    OrdHdr.Setrange("Order Type",Rec."Shopify Order Type"::Invoice);
                                    If OrdHdr.findset then
                                    begin
                                        PG.SetTableView(OrdHdr);
                                        Pg.Run;
                                    end
                                    else
                                        Message('Invoice does not exist');
                                end    
                            end;
                            2:
                            begin
                                GLEnt.Reset;
                                GLSetup.get;
                                Case Rec."Payment Gate Way" of
                                    Rec."Payment Gate Way"::"Shopify Pay":
                                    Glent.Setrange("G/L Account No.",GLSetup."Shopify Pay Clearing Acc");
                                    Rec."Payment Gate Way"::Paypal:
                                    Glent.Setrange("G/L Account No.",GLSetup."PayPal Clearing Acc");
                                    Rec."Payment Gate Way"::AfterPay:
                                    Glent.Setrange("G/L Account No.",GLSetup."AfterPay Clearing Acc");
                                    Rec."Payment Gate Way"::Zip:
                                    Glent.Setrange("G/L Account No.",GLSetup."Zip Clearing Acc");
                                    Rec."Payment Gate Way"::MarketPlace:
                                    Glent.Setrange("G/L Account No.",GLSetup."MarketPlace Clearing Acc");
                                    Rec."Payment Gate Way"::Misc:
                                    Glent.Setrange("G/L Account No.",GLSetup."Misc Clearing Acc");
                                end;
                                Glent.Setrange("Document Type",Glent."Document Type"::Payment);
                                If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Refund then
                                Glent.Setrange("Document Type",Glent."Document Type"::Refund);
                                GlEnt.Setfilter(Description,'*' + Format(Rec."Shopify Order No") + '*');
                                If Glent.FindSet() then
                                begin
                                    GLPag.SetTableView(Glent);
                                    GlPag.RunModal();
                                end
                                else
                                    Message('Entries Not Found');
                           end;
                        end;
                    end;            
                }
                field("Shopify Order Date"; Rec."Shopify Order Date")
                {
                    ApplicationArea = All;
                }
                field("BC Reference No.";Get_BC_Document())
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        SinvHdr: Record "Sales Invoice Header";
                        SCrdHdr: Record "Sales Cr.Memo Header";
                        CustLedg:record "Cust. Ledger Entry";
                    begin
                        Case Strmenu('Show Document,Show Remaining Amount',1) of
                            1:
                            Begin
                                if SinvHdr.get(Get_BC_Document()) then
                                    Page.RunModal(Page::"Posted Sales Invoice", SinvHdr)
                                else if ScrdHdr.get(Get_BC_Document()) then
                                    Page.RunModal(Page::"Posted Sales Credit Memo", ScrdHdr);
                                CurrPage.update(false);
                            end;
                            2:
                            begin
                                CustLedg.reset;
                                CustLedg.Setrange("Document Type",CustLedg."Document Type"::Invoice);
                                If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Refund then
                                    CustLedg.Setrange("Document Type",CustLedg."Document Type"::"Credit Memo");
                                CustLedg.Setrange("Document No.",Get_BC_Document());
                                iF CustLedg.FindSet() then
                                begin
                                    CustLedg.CalcFields("Remaining Amount");
                                    If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Invoice then
                                        Message(StrsubStno('Invoice Remaining Amount = %1',CustLedg."Remaining Amount"))
                                    else
                                        Message(StrsubStno('CreditNote Remaining Amount = %1',ABS(CustLedg."Remaining Amount")));
                                end
                                Else
                                    Message('Document Not Found!');
                            end;        
                        end;
                    end;    
                }
                field("Payment Gate Way"; Rec."Payment Gate Way")
                {
                    ApplicationArea = All;
                }
                field("Reference No";rec."Reference No")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Order Total"; Rec."Order Total")
                {
                    ApplicationArea = All;
                }
                field("Apply Status"; Rec."Apply Status")
                {
                    ApplicationArea = All;
                    StyleExpr = Styler;
                    Editable = EditFlg;
                    trigger OnAssistEdit()
                    begin
                        EditFlg := confirm('Allow Editing',true);
                        CurrPage.update(false);
                    end;
                }
            }
            Group(Totals)
            {
                field("Filtered Order Count"; Rec.Count)
                {
                    ApplicationArea = All;
                }
                field("Filtered Sales Totals";Get_Sales_Totals(true))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Filtered Refund Totals";Get_Sales_Totals(false))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Total CashApplied Payment Type Sales";Get_Totals(true))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Total Completed Payment Type Sales";Get_Totals(false))
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            Group(Refunds)
            {
                Caption = 'Refund Order Management';
                action("PCA")
                {
                    ApplicationArea = All;
                    Caption = 'Update Unprocessed Refunds';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        Cu: Codeunit "PC Shopify Routines";
                        Cnt:Integer;
                    begin
                        If Confirm('Update Unprocessed Refunds Now?',True) then
                        Begin
                            Cnt := CU.Process_Current_Refunds(True);
                            If Cnt > 0 then
                            begin
                                Cu.Process_Orders(false,0);
                                Message('%1 Refunds have been updated and processed',Cnt)
                            end; 
                        end;
                        CurrPage.update(false);
                   end;
                 }
            }
            Group(Entries) 
            {   
                Caption = 'Entries';
                action("PCB")
                {
                    ApplicationArea = All;
                    Caption = 'Process Cash Applied Entries';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        Cu: Codeunit "PC Reconcillations";
                    begin
                        If PSTDate <> 0D Then
                        begin
                            If Confirm(Strsubstno('Process Cash Applied Entries Using Posting Date %1 Now?',Pstdate),True) then
                            begin
                                CU.Apply_Entries(PStDate);
                                Clear(PstDate);
                            end;
                        end 
                        else
                            Message('Please supply a posting date');    
                   End;
                }
                action("PCC")
                {
                    ApplicationArea = All;
                    Caption = 'Unapply/Reverse Transaction entries';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        Cu: Codeunit "PC Reconcillations";
                        Pg:Page "PC Reverse Apply Selections";
                        Sel:Record Item;
                    begin
                        Case Strmenu('All Doc Entries,Selected Doc Entry',2) of
                            1:
                                If Confirm('Are You Absolutely Sure You wish To Unapply and Reverse All Completed entries Now',False) then
                                If Confirm('This will take a very long time to complete are you sure this is what you want to do?',false) then
                                    Cu.Reverse_Reconcillation_Transactions('');
                            2:
                            Begin
                                pg.LookupMode := true;
                                Case Strmenu('Cash Applied Docs,Completed Docs',1) of
                                    0:Exit;
                                    1: Pg.SetApplyType(1);
                                    else 
                                        Pg.SetApplyType(2);
                                end;
                                If Pg.RunModal() = Action::LookupOK then
                                begin
                                    Pg.GetRecord(Sel);
                                    If Confirm(strsubstno('Proceed using %1 document now?',Sel."No."),true) then
                                          Cu.Reverse_Reconcillation_Transactions(Sel."no.");
                                end;
                            end;         
                        end;            
                    end;
                }    
            /*    action("PCE")
                {
                    ApplicationArea = All;
                    Caption = 'Fix Invalid Entries';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        Glent:record "G/L Entry";
                        GLSetup:Record "General Ledger Setup";
                        Recon:Record "PC Order Reconciliations";
                    begin
                        GLSetup.get;
                        Recon.reset;
                        Recon.Setrange("Apply Status",Recon."Apply Status"::CashApplied);
                        Recon.setfilter("Order Total",'>0');
                        If Recon.findset then
                        repeat
                            GLEnt.Reset;
                            Case Recon."Payment Gate Way" of
                                Recon."Payment Gate Way"::"Shopify Pay":
                                Glent.Setrange("G/L Account No.",GLSetup."Shopify Pay Clearing Acc");
                                Recon."Payment Gate Way"::Paypal:
                                Glent.Setrange("G/L Account No.",GLSetup."PayPal Clearing Acc");
                                Recon."Payment Gate Way"::AfterPay:
                                Glent.Setrange("G/L Account No.",GLSetup."AfterPay Clearing Acc");
                                Recon."Payment Gate Way"::Zip:
                                Glent.Setrange("G/L Account No.",GLSetup."Zip Clearing Acc");
                                Recon."Payment Gate Way"::MarketPlace:
                                Glent.Setrange("G/L Account No.",GLSetup."MarketPlace Clearing Acc");
                                Recon."Payment Gate Way"::Misc:
                                Glent.Setrange("G/L Account No.",GLSetup."Misc Clearing Acc");
                            end;
                            Glent.Setrange("Document Type",Glent."Document Type"::Payment);
                            If Recon."Shopify Order Type" = Recon."Shopify Order Type"::Refund then
                            Glent.Setrange("Document Type",Glent."Document Type"::Refund);
                            GlEnt.Setfilter(Description,'*' + Format(Recon."Shopify Order No") + '*');
                            If Not Glent.FindSet() then
                            begin
                                Recon."Apply Status" := Recon."Apply Status"::UnApplied;
                                Recon.modify(false);    
                            end;
                        until recon.next = 0;    
                    end;
                }*/
           }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Styler := 'strong';
        If rec."Apply Status" = rec."Apply Status"::CashApplied then
            Styler := 'strongaccent'
        else If rec."Apply Status" = rec."Apply Status"::Completed then
            Styler := 'favorable';
    end;

    trigger OnOpenPage()
    var
     begin
        ApplyStat := ApplyStat::UnApplied;
        MFee := '519000';
        Setfilters();
    end;
    Local Procedure Get_BC_Document():Code[20]
    var
        OrdHdr:record "PC Shopify Order Header";
    begin
        OrdHdr.Reset();
        If Rec."Refund Shopify ID" <> 0 then
            OrdHdr.Setrange("Shopify Order ID",rec."Refund Shopify ID")
        else
            OrdHdr.Setrange("Shopify Order ID",rec."Shopify Order ID");
        OrdHdr.Setrange("Order Type",Rec."Shopify Order Type");
        If OrdHdr.FindSet() then
            Exit(OrdHdr."BC Reference No.");
        Exit('');    
    end;
    local procedure Get_Sales_Totals(Mode:Boolean):Decimal
    var
        buff:Record "PC Order Reconciliations";
    begin
        Buff.CopyFilters(Rec);
        If OrdType = OrdType::All then
            if Mode then
                Buff.Setfilter("Shopify Order Type",'%1|%2',Buff."Shopify Order Type"::Invoice,Buff."Shopify Order Type"::Cancelled)
            else    
                Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::refund);
        If (OrdType in [OrdType::Invoice,OrdType::Cancelled]) And Not Mode Then Exit(0);
        If (OrdType = OrdType::Refund) And Mode Then Exit(0);
        If Buff.findset then
        begin
            Buff.CalcSums("Order Total");
            exit(Buff."Order Total");
        end;        
        exit(0);    
    end;
    local procedure Get_Totals(Mode:Boolean):Decimal
    var
        buff:Record "PC Order Reconciliations";
        OrdTotal:Decimal;
    begin
        Clear(OrdTotal);
        Buff.Reset;
        If Mode then
        begin
            Buff.Setrange("Apply Status",Buff."Apply Status"::CashApplied);
            Buff.Setfilter("Shopify Order Type",'%1|%2',Buff."Shopify Order Type"::Invoice,Buff."Shopify Order Type"::Cancelled);
            If Payments <> Payments::All then
                Buff.Setrange("Payment Gate Way",Payments);
            begin
                Buff.CalcSums("Order Total");
                OrdTotal := Buff."Order Total";
            End;
            Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::Refund);
            If Buff.findset then
            begin
                Buff.CalcSums("Order Total");
                OrdTotal -= Buff."Order Total";
            end;
            exit(OrdTotal);  
        end     
        else
        begin    
            Buff.Setrange("Apply Status",Buff."Apply Status"::Completed);
            Buff.Setfilter("Shopify Order Type",'%1|%2',Buff."Shopify Order Type"::Invoice,Buff."Shopify Order Type"::Cancelled);
            If Payments <> Payments::All then
                Buff.Setrange("Payment Gate Way",Payments-1);
            If Buff.findset then
            begin;
                Buff.CalcSums("Order Total");
                OrdTotal := Buff."Order Total";
            End;
            Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::Refund);
            If Buff.findset then
            begin
                Buff.CalcSums("Order Total");
                OrdTotal -= Buff."Order Total";
            end;
            exit(OrdTotal);
        end;      
    end;
    local procedure Check_GL_Balance():Boolean
    var
        Glent:record "G/L Entry";
        GLSetup:Record "General Ledger Setup";
        win:dialog;
        j:Decimal;
    begin
        GLSetup.get;
        Rec.ClearMarks();
        Rec.Reset;
        Case Strmenu('ALL,Check Cashapplied Entries,Check Completed Entries',1) of
            0:Exit;
            2:Rec.Setrange("Apply Status",Rec."Apply Status"::CashApplied);
            3:Rec.Setrange("Apply Status",Rec."Apply Status"::Completed);
        end;
        Case Strmenu('All,Shopify Pay,PayPal,AfterPay,Zip,MarketPlace,Misc',1) of
            0:Exit;
            2:Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::"Shopify Pay");
            3:Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::Paypal);
            4:Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::AfterPay);
            5:Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::Zip);
            6:Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::MarketPlace);
            else
                Rec.Setrange("Payment Gate Way",Rec."Payment Gate Way"::Misc);
        end;
        Win.Open('Progress @1@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
                +'Checking Order No #2############### Status #3#####');
        GLSetup.get;
        GLEnt.Reset;
        Clear(j);
        Rec.SetFilter("Order Total",'>0');
        If Rec.findset then
        repeat
            j+= 10000/Rec.Count;
            Win.update(1,j DIV 1);
            Case Rec."Payment Gate Way" of
                Rec."Payment Gate Way"::"Shopify Pay":
                Glent.Setrange("G/L Account No.",GLSetup."Shopify Pay Clearing Acc");
                Rec."Payment Gate Way"::Paypal:
                Glent.Setrange("G/L Account No.",GLSetup."PayPal Clearing Acc");
                Rec."Payment Gate Way"::AfterPay:
                Glent.Setrange("G/L Account No.",GLSetup."AfterPay Clearing Acc");
                Rec."Payment Gate Way"::Zip:
                Glent.Setrange("G/L Account No.",GLSetup."Zip Clearing Acc");
                Rec."Payment Gate Way"::MarketPlace:
                Glent.Setrange("G/L Account No.",GLSetup."MarketPlace Clearing Acc");
                Rec."Payment Gate Way"::Misc:
                Glent.Setrange("G/L Account No.",GLSetup."Misc Clearing Acc");
            end;
            Glent.Setrange("Document Type",Glent."Document Type"::Payment);
            If Rec."Shopify Order Type" = Rec."Shopify Order Type"::Refund then
                Glent.Setrange("Document Type",Glent."Document Type"::Refund);
            GlEnt.Setfilter(Description,'*' + Format(Rec."Shopify Order No") + '*');
            Win.update(2,Format(Rec."Shopify Order No"));
            If Glent.FindSet() then
            begin
                Glent.CalcSums(Amount);
                If Rec."Apply Status" = Rec."Apply Status"::CashApplied then
                begin
                    If Rec."Shopify Order Type" in [Rec."Shopify Order Type"::Invoice,Rec."Shopify Order Type"::Cancelled] then
                        rec.Mark(Glent.Amount + Rec."Order Total" <> 0)
                    else
                        Rec.Mark(Glent.Amount - Rec."Order Total" <> 0);
                end
                else
                    Rec.Mark(Glent.Amount <> 0); 
            end
            else
                rec.Mark(true);
            If Rec.Mark then 
                Win.Update(3,'FAIL')
            else    
                Win.Update(3,'PASS')       
        until Rec.next = 0;
        Win.Close;                        
    end;
    Local procedure Setfilters()
    Begin
        Rec.Reset();
        If OrdType <> OrdType::All then
            Rec.SetRange("Shopify Order Type",OrdType - 1);
        if (OrdDateFilter[1] <> 0D) AND (OrdDateFilter[2] <> 0D) then
            rec.SetRange("Shopify Order Date", OrdDateFilter[1], OrdDateFilter[2])
               else if (OrdDateFilter[1] <> 0D) then
            rec.Setfilter("Shopify Order Date", '%1..', OrdDateFilter[1])
        else if (OrdDateFilter[2] <> 0D) then
            rec.Setfilter("Shopify Order Date", '..%1', OrdDateFilter[2]);
        If Payments <> Payments::All then
            Rec.Setrange("Payment Gate Way",Payments);    
        If ApplyStat <> ApplyStat::All then
            Rec.Setrange("Apply Status",ApplyStat - 1); 
        CurrPage.update(False);       
    End;
   
    var
        Payments:Option All,"Shopify Pay",Paypal,AfterPay,Zip,MarketPlace,Misc;
        OrdDateFilter:Array[2] of Date;
        ApplyStat:Option All,UnApplied,CashApplied,Complete;
        OrdType:Option All,Invoice,Refund,Cancelled;
        pstDate:Date;
        Styler:text;
        MFee:code[20];
        EditFlg:Boolean;
}
