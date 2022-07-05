page 80006 "PC Shopify Orders"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "PC Shopify Order Header";
    InsertAllowed = false;
    ShowFilter = false;
    Caption = 'Shopify Orders';

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field("Clear Filters"; 'Clear Filters')
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        Clear(TransFilter);
                        Clear(OrdDateFilter);
                        Clear(Stat);
                        Clear(Type);
                        clear(Fstat);
                        Clear(OrdStat);
                        Clear(OrdNo);
                        SetFilters();
                    end;
                }
                field("From Transaction Date Filter"; TransFilter[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[2] <> 0D then
                            if TransFilter[1] > TransFilter[2] then Clear(Transfilter[1]);
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[1]);
                        SetFilters();
                    end;
                }
                field("To Transaction Date Filter"; TransFilter[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[1] <> 0D then
                            if TransFilter[2] < TransFilter[1] then Clear(Transfilter[2]);
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[2]);
                        SetFilters();
                    end;
                }
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
                field("Status Filter"; Stat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Stat);
                        SetFilters();
                    end;
                }
                field("Fulfilio Shipment Status Filter"; FStat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(FStat);
                        SetFilters();
                    end;
                }
                field("Order Type Filter"; Type)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(Type);
                        SetFilters();
                    end;
                }
                field("Shopify Order Status Filter"; ordStat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdStat);
                        SetFilters();
                    end;
                }
                field("Shopify Order No Filter"; ordNo)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdNo);
                        SetFilters();
                    end;
                }
                field("Shopify Order ID Filter"; ordID)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(OrdID);
                        SetFilters();
                    end;
                }
                Field("EX";'Show Exceptions Only')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        ShowExceptions();
                    end;
                    trigger OnAssistEdit()
                    begin
                       SetFilters();
                    end;
                }
            }
            repeater(Control)
            {
                ShowCaption = false;
                field("Transaction Date"; rec."Transaction Date")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Order Date"; rec."Shopify Order Date")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Order Type"; rec."Order Type")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Member Status"; rec."Shopify Order Member Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Member Status';
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Shopify Invoice/Credit No."; rec."Shopify Order No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        cu:Codeunit "PC Shopify Routines";
                    begin
                        If confirm('Retrieve Orders Using this record as Start index',False) then
                            Cu.Get_Shopify_Orders(Rec."Shopify Order ID");
                    end;
                    trigger OnAssistEdit()
                    var
                        OrdLine:record "PC Shopify Order Lines";
                        Item:Record Item;
                        Cu: codeunit "PC Shopify Routines";
                        Excp: Record "PC Shopify Order exceptions";
                     begin
                        If rec."BC Reference No." = '' then 
                        begin
                            If Confirm('Are you sure you wish to force process this order now',false) then
                            begin
                                OrdLine.Reset();
                                Ordline.setrange(ShopifyID,rec.ID);
                                If OrdLine.findset then
                                begin
                                    repeat
                                        if not Item.Get(OrdLine."Item No.") then
                                            Error('Item No %1 does not exist .. aborting',OrdLine."Item No.");
                                        OrdLine."Location Code" := 'NSW';
                                        OrdLine."Unit Of Measure" := Item."Base Unit of Measure";
                                        OrdLine."FulFilo Shipment Qty" := OrdLine."Order Qty";
                                        OrdLine.Modify();
                                    until OrdLine.next = 0;
                                    Excp.reset;
                                    Excp.Setrange(ShopifyID,rec.ID);
                                    If Excp.Findset then Excp.deleteall;
                                    Cu.Process_Orders(true,Rec.ID);
                                    CurrPage.update(false);
                                end;                
                            end;             
                        end;
                    end;
                }
                field("BC Order No."; rec."BC Reference No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        SinvHdr: Record "Sales Invoice Header";
                        SCrdHdr: Record "Sales Cr.Memo Header";
                        SoHdr: Record "Sales Header";
                    begin
                        If SoHdr.get(SoHdr."Document Type"::invoice, rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Invoice", Sohdr)
                        else If SoHdr.get(SoHdr."Document Type"::"Credit Memo", rec."BC Reference No.") then
                            Page.RunModal(Page::"Sales Credit Memo", Sohdr)
                        else if SinvHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Invoice", SinvHdr)
                        else if ScrdHdr.get(rec."BC Reference No.") then
                            Page.RunModal(Page::"Posted Sales Credit Memo", ScrdHdr);
                         CurrPage.update(false);
                    end;
                    trigger OnAssistEdit()
                    var
                        SInv:Record "Sales Invoice Header";
                        SCrd:Record "Sales Cr.Memo Header";
                        SOrdHr:Record "PC Shopify Order Header";
                    begin
                        If (Rec."Order Type" = Rec."Order Type"::Invoice) 
                            And Not SInv.Get(rec."BC Reference No.") then
                       begin
                            If  Confirm('Update Entry Now',True) then
                            begin
                                SInv.Reset;
                                Sinv.Setrange("Pre-assigned No.",Rec."BC Reference No.");
                                If Sinv.Findset then
                                begin
                                    SOrdHr.reset;
                                    SOrdHr.Setrange("BC Reference No.",Rec."BC Reference No.");
                                    If SOrdHr.Findset then
                                    repeat
                                        SOrdHr."BC Reference No." := SInv."No.";
                                        SOrdHr."Order Status" := SOrdHr."Order Status"::Closed;
                                        SOrdHr.Modify(false);
                                    until SOrdHr.next = 0;    
                                    CurrPage.update(false);
                                end;       
                            end;
                       end;    
                        If (Rec."Order Type" = Rec."Order Type"::CreditMemo) 
                            And Not SCrd.Get(rec."BC Reference No.") then
                         begin
                            If Confirm('Update Entry Now',True) then
                            begin
                                SCrd.Reset;
                                SCrd.Setrange("Pre-assigned No.",Rec."BC Reference No.");
                                If SCrd.Findset then
                                begin
                                    SOrdHr.reset;
                                    SOrdHr.Setrange("BC Reference No.",Rec."BC Reference No.");
                                    If SOrdHr.Findset then
                                    repeat
                                        SOrdHr."BC Reference No." := SCrd."No.";
                                        SOrdHr."Order Status" := SOrdHr."Order Status"::Closed;
                                        SOrdHr.Modify(false);
                                    until SOrdHr.next = 0;    
                                    CurrPage.update(false);
                                end;       
                            end;
                        end;
                    end;    
                }
                field("Currency Code"; rec."Shopify Order Currency")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Order Total"; rec."Order Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                    trigger OnAssistEdit()
                    var
                        Cu:Codeunit "PC Shopify Routines";
                    begin
                        If Confirm('Preform A Credit Correction Now',False) then;
                    end;    


                }
 /*               field("Credit Card Total"; rec."Credit Card Total")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Store Credit Total"; rec."Store Credit Total")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                */
                field("Gift Card Total"; rec."Gift Card Total")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Discount Total"; rec."Discount Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }

                field("Freight Total"; rec."Freight Total")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Fulfilo Shipment Status"; rec."Fulfilo Shipment Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Fulfilo Shipment Status" = rec."Fulfilo Shipment Status"::Complete;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field("Shopify Order Status"; rec."Shopify Order Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        Show_Order_Lines();
                    end;
                }
                field(MSG1; Apps)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        If Apps <> '*' then Show_Order_Apps_Lines();
                    end;
                }
                field(MSG2; Excpt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    Editable = False;
                    trigger OnDrillDown()
                    begin
                        If Excpt <> '*' then Show_Exception_Lines();
                    end;
                }
                field(MSG3; Proc)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        Cu: codeunit "PC Shopify Routines";
                        Excp: Record "PC Shopify Order exceptions";
                        Sel:Integer;
                    begin
                        If Proc <> '*' then 
                        begin
                            if Confirm('Attempt to reprocess this order Now', True) then 
                            begin
                                Sel := StrMenu('Via Fulfilio Check,ByPass Fulfilio Check',1);
                                If Sel > 0 then
                                begin
                                    Excp.Reset;
                                    Excp.Setrange(ShopifyID, rec.ID);
                                    If Excp.Findset then Excp.Deleteall;
                                    If Sel = 1 then
                                    begin 
                                        Rec."Fulfilo Shipment Status" := Rec."Fulfilo Shipment Status"::InComplete;
                                        Rec.modify(false);
                                        CurrPage.update(true);        
                                        Cu.Process_Orders(false, Rec.ID);
                                    end    
                                    else    
                                        Cu.Process_Orders(true, Rec.ID);
                                end;    
                            end;
                            SetFilters();
                        end;
                    end;
                }
                field("Status"; rec."Order Status")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = rec."Order Status" = rec."Order Status"::Closed;
                }
                field("Shopify Order ID"; rec."Shopify Order ID")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Refunds Checked";rec."Refunds Checked")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
            Group(Totals)
            {
                field("Filtered Record Count"; rec.Count)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = True;
                }
            }
                field("Filtered Record Value"; Get_Value())
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = True;
                }
        }
    }
    actions
    {
        area(Processing)
        {
            Group(MOrders)
            {
                Caption = 'Order Management';
                action("PCA")
                {
                    ApplicationArea = All;
                    Caption = 'Retrieve Shopify Orders';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    trigger OnAction()
                    var
                        Cu: Codeunit "PC Shopify Routines";
                    begin
                        If Confirm('Retrieve Orders From Shopify Now?', True) then
                            Cu.Get_Shopify_Orders(0);
                        CurrPage.update(false);
                    end;
                }
                action("Process Shopify Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Process Shopify Orders';
                    Image = Change;
                    Promoted = true;
                    PromotedIsBig = true;
                    ToolTip = 'Processes Received Shopify Orders into BC Orders';
                    trigger OnAction()
                    var
                        cu: Codeunit "PC Shopify Routines";
                        Cust: Record Customer;
                        Pg: page "Customer Lookup";
                        Flg: boolean;
                    begin
                        If confirm('Process Shopify Orders into BC Orders now?', true) then 
                        begin
                            If cu.Process_Orders(false, 0) Then
                                message('Processing Operation Completed Successfully')
                            else
                                Message('Processing Operation Completed Unsuccessfully');
                        end;
                    end;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        Excp: Record "PC Shopify Order exceptions";
        SApp: Record "PC Shopfiy Order Applications";
        DApp:record "PC Shopify Disc Apps";
    begin
        Excpt := '*';
        Excp.Reset;
        Excp.Setrange(ShopifyID, rec.ID);
        If Excp.Findset then Excpt := 'Exception';
        Apps := '*';
        SApp.reset;
        SApp.Setrange(ShopifyID, rec.ID);
        If SAPP.FindSet() then
            If DApp.get(SApp."Shopify Application Type",SApp."Shopify Disc App Code",SAPP."Shopify Disc App Value") then
                Apps := 'Order Apps';
        Proc := '*';
        If Excpt <> '*' then Proc := 'Process';
    end;

    Local procedure Show_Order_Lines()
    var
        Pg: page "PC Shopify Order Lines";
        OrdL: Record "PC Shopify Order Lines";
    begin
        OrdL.reset;
        OrdL.Setrange(ShopifyID, rec.ID);
        If Ordl.FindSet() then begin
            Pg.SetTableView(OrdL);
            Pg.RunModal();
            CurrPage.update(false);
         end
        else
            Message('No Order Lines Exists');
    end;
    local procedure ShowExceptions()
    var
        Excp: Record "PC Shopify Order exceptions";
    begin
        rec.reset;
        rec.ClearMarks();
        Excp.reset;
        If Excp.findset then
        repeat
            Rec.get(Excp.ShopifyID);
            Rec.Mark(True);
        until excp.next = 0;
        rec.MarkedOnly(true);
        Currpage.update(false);
    end;
    local Procedure Get_Value():Decimal
    begin
        Rec.CalcSums(Rec."Order Total");
        Exit(Rec."Order Total");
    end;
    Local procedure Show_Order_Apps_Lines()
    var
        Pg: page "PC Shopify Applications";
        SApp: Record "PC Shopfiy Order Applications";
        App: record "PC Shopify Disc Apps";
    begin
        SApp.reset;
        SApp.Setrange(ShopifyID, rec.ID);
        If SAPP.FindSet() then begin
            App.Reset;
            App.Setrange("Shopify Discount App Type", Sapp."Shopify Application Type");
            App.Setrange("Shopify Disc App Code", Sapp."Shopify Disc App Code");
            App.Setrange("Shopify Value",Sapp."Shopify Disc App Value");
            if App.findset then begin
                Pg.SetTableView(APP);
                Pg.RunModal();
                CurrPage.update(false);
            end;
        end
        else
            Message('No Application Lines Exists');
    end;

    local procedure Show_Exception_Lines()
    var
        Excp: record "PC Shopify Order Exceptions";
        pg: page "PC Shopify Order Exceptions";
    begin
        Excp.reset;
        Excp.Setrange(ShopifyID, rec.ID);
        If Excp.Findset then begin
            Pg.SetTableView(Excp);
            Pg.RunModal();
        end;
    end;
    local procedure SetFilters()
    begin
        rec.Reset;
        if (TransFilter[1] <> 0D) AND (TransFilter[2] <> 0D) then
            rec.SetRange("Transaction Date", TransFilter[1], TransFilter[2])
        else if (TransFilter[1] <> 0D) then
            rec.Setfilter("Transaction Date", '%1..', TransFilter[1])
        else if (TransFilter[2] <> 0D) then
            rec.Setfilter("Transaction Date", '..%1', TransFilter[2]);
        if (OrdDateFilter[1] <> 0D) AND (OrdDateFilter[2] <> 0D) then
            rec.SetRange("Shopify Order Date", OrdDateFilter[1], OrdDateFilter[2])
        else if (OrdDateFilter[1] <> 0D) then
            rec.Setfilter("Shopify Order Date", '%1..', OrdDateFilter[1])
        else if (OrdDateFilter[2] <> 0D) then
            rec.Setfilter("Shopify Order Date", '..%1', OrdDateFilter[2]);
        If Stat <> Stat::" " then rec.Setrange("order Status", Stat - 1);
        If FStat <> FStat::" " then rec.Setrange("Fulfilo Shipment Status", fStat - 1);
        If OrdID <> 0 then rec.SetRange("Shopify Order ID",OrdID);
        If Type <> Type::" " then rec.Setrange("Order Type", Type - 1);
        Case OrdStat of
            OrdStat::FULFILLED : Rec.SetRange("Shopify Order Status",'FULFILLED');
            OrdStat::PARTIAL : Rec.SetRange("Shopify Order Status",'PARTIAL');
            OrdStat::NULL : Rec.Setrange("Shopify Order Status",'NULL');
        end;
        If OrdNo <> 0 then rec.Setrange("Shopify Order No.",OrdNo);    
        Currpage.Update(False);
    end;

    var
        TransFilter: array[2] of date;
        OrdDateFilter: array[2] of date;
        Stat: option " ",Open,Closed;
        Type: option " ",Invoice,"Credit Memo";
        Fstat: option " ",Incomplete,Complete;
        OrdNo:Integer;
        OrdID:BigInteger;
        Excpt: text[20];
        Apps: text[20];
        Proc: text[20];
        OrdStat: Option " ",FULFILLED,PARTIAL,NULL;

}
