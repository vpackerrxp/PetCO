page 80021 "PC Inventory Maintenance"
{
    Caption = 'Inventory Maintenance';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = Item;
    SourceTableView = where(type=Const(Inventory));
    InsertAllowed = false;
    //ModifyAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;   

    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            Group(Filters)
            {
                field("Location Filter"; LOC)
                {
                    ApplicationArea = All;
                    TableRelation = Location where("Use As In-Transit"=Const(false),Code=filter(<>'QC'));
                    trigger OnValidate()
                    begin
                        If Reason > 0 then
                            Process_Reasons()
                        else            
                            SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(LOC);
                        If Reason > 0 then
                            Process_Reasons()
                        else            
                            SetFilters();
                    end;
                }                   
                field("SKU Filter";Sku)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where(type=Const(Inventory));
                    trigger OnValidate()
                    begin 
                        If not SkuLst.Contains(Sku) then
                            Skulst += SKU + '|';
                        Clear(sku);
                        If Reason > 0 then
                            Process_Reasons()
                        else    
                            SetFilters();   
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SKU);
                        Clear(SkuLst);
                        If Reason > 0 then
                            Process_Reasons()
                        else    
                            SetFilters();   
                    end;
                }
                Field("Sku List";Skulst)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    MultiLine = true;
                    Editable = false;    
                }        
                grid(Supplier)
                {
                    ShowCaption = false;
                    field("Supplier Filter";Supp)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        TableRelation = Vendor where("No."=Filter('SUP-*'));
                        trigger OnValidate()
                        var
                            Ven:Record Vendor;
                        begin 
                            Clear(Name);
                            If Ven.get(Supp) then Name := Ven.Name;    
                            If Reason > 0 then
                                Process_Reasons()
                            else    
                                SetFilters();   
                        end;
                        trigger OnAssistEdit()
                        begin
                            Clear(Supp);
                            Clear(Name);
                            If Reason > 0 then
                                Process_Reasons()
                            else    
                                SetFilters();   
                        end;
                    }
                    field("";Name)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        editable = false;
                    }
                }
                Group(Brand)
                {
                    ShowCaption = false;
                    field("Brand Filter"; Bran)
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            pg:page "PC Supplier Brand List";
                            rel:Record "PC Supplier Brand Rebates";
                        begin
                            Rel.Reset;
                            pg.SetTableView(rel);
                            pg.LookupMode := true;
                            If Pg.RunModal() = action::LookupOK then
                            begin
                                pg.GetRecord(Rel);
                                If not BranLst.Contains(Rel.Brand) then
                                    Branlst += Rel.Brand + '|';
                                Clear(Bran);
                                If Reason > 0 then
                                    Process_Reasons()
                                else    
                                    SetFilters();   
                             end;      
                        end; 
                        trigger OnAssistEdit()
                        begin
                            Clear(Bran);
                            Clear(Branlst);
                            If Reason > 0 then
                                Process_Reasons()
                            else    
                                SetFilters();   
                        end;
                    }
                    Field("Brand List";Branlst)
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        MultiLine = true;
                        Editable = false;    
                    }        
                }
                Group("Reasons")
                {
                    ShowCaption = False;
                    field("Fulfilio Reason Filter";Reason)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        Trigger OnValidate()
                        begin
                            Process_Reasons();
                        end;
                        trigger OnAssistEdit()
                        begin
                            Clear(Reason);
                            Clear(ReasCode);
                            SetFilters();
                            EnbFlg := ReasCode = '';    
                        end;    
                    }    
                    Field("Include BC Adjusted Entries";Inc)
                    {
                        ApplicationArea = all;
                        trigger OnValidate()
                        begin
                            Process_Reasons();
                        end;        
                    }
                    field("Fulfilio Delta Days Offset";Offset)
                    {
                        ApplicationArea = all;
                        trigger OnValidate() 
                        var
                            Cu:Codeunit "PC Fulfilio Routines";
                        begin
                            If Offset = 0 then offset := 7;
                            CurrPage.Update(false);
                            If Confirm(StrSubstNo('Refresh Fulfilio Data using %1 Days Offset now',Offset),True) then
                            begin
                                Clear(Supp);
                                Clear(Loc);
                                Clear(name);
                                Clear(SkuLst);
                                CLear(SKU);
                                Clear(Branlst);
                                Clear(Bran);
                                Clear(Reason);
                                Clear(ReasCode);
                                Clear(Inc);
                                Rec.ClearMarks();
                                SetFilters();
                                Cu.Build_Fulfilo_Inventory_Levels();
                                Cu.Build_Fulfilo_Inventory_Deltas(Offset)      
                            end;
                        end;
                    }        
                }
                field("A";'Clear All Filters')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        Clear(Supp);
                        Clear(Loc);
                        Clear(name);
                        Clear(SkuLst);
                        CLear(SKU);
                        Clear(Bran);
                        Clear(Branlst);
                        Clear(Reason);
                        Clear(ReasCode);
                        Clear(Inc);
                        Rec.ClearMarks();
                        SetFilters();
                    end;    
                }
                Grid(Refresh)
                {
                    ShowCaption = false;
                    field("B";'Refresh Fulfilio Data')
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        ShowCaption = false;
                        trigger OnDrillDown()
                        var
                            Cu:Codeunit "PC Fulfilio Routines";
                        begin
                            Clear(Supp);
                            Clear(Loc);
                            Clear(name);
                            Clear(SkuLst);
                            CLear(SKU);
                            Clear(Bran);
                            Clear(Branlst);
                            Clear(Reason);
                            Clear(ReasCode);
                            Clear(Inc);
                            Rec.ClearMarks();
                            SetFilters();
                            If Confirm('Refresh Fulfilio Data Now',True) then
                            Begin
                                Cu.Build_Fulfilo_Inventory_Levels();
                                Cu.Build_Fulfilo_Inventory_Deltas(Offset);
                                Clear(RefMsg);
                                CurrPage.update(False);
                            end;          
                        end;    
                    }
                    field("REF";RefMsg)
                    {
                        ApplicationArea = all;
                        StyleExpr = 'favorable';
                        ShowCaption = false;
                        Editable = false;
                    }
                }    
                field("C";'Show Adjustments Only')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    Enabled = EnbFlg;
                    trigger OnDrillDown()
                    var
                    begin
                        SetFilters();
                        if Rec.Findset then
                        repeat
                            rec.Mark(rec."Fulfilo Inventory" - (rec.Inventory + rec."Fulfilo Qty On PO") <> 0); 
                        Until Rec.next = 0;    
                        rec.MarkedOnly(true);
                        CurrPage.update(false);
                    end;
                }
                field("D";'Show All')
                {
                    ApplicationArea = all;
                    Style = Strong;
                    ShowCaption = false;
                    Enabled = EnbFlg;
                    trigger OnDrillDown()
                    var
                    begin
                        Rec.ClearMarks();
                        SetFilters();
                    end;
                }
            }    
            repeater(Group)
            {
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown();
                    var
                        Pg:page "Item Card";
                    begin
                        Pg.SetRecord(Rec);
                        Pg.runmodal;     
                        CurrPage.update(false);
                     end;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("BC Inventory"; rec.Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'BC Inventory';
                }
                field("Qty On PO"; rec."Qty. on Purch. Order")
                {
                    ApplicationArea = All;
                }
                field("Fulfilio Qty On PO"; rec."Fulfilo Qty On PO")
                {
                    ApplicationArea = All;
                    Caption = 'Fulfilio Qty On PO';
                }
                field("Fulfilio Inventory Qty"; rec."Fulfilo Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Fulfilio Inventory Qty';
                }
                field("Fulfilio Inventory Reasons"; rec."Fulfilo Reason Count")
                {
                    ApplicationArea = All;
                    caption = 'Fulfilio Inventory Reasons';
                    trigger OnDrillDown()
                    var
                        Pg:Page "PC Fulfilo Inv Reasons";
                        Res:Record "PC Fulfilo Inv. Delta Reasons";    
                    begin
                        If rec."Fulfilo Reason Count" > 0 then
                        begin
                            Res.Reset;
                            Res.Setrange(SKU,rec."No.");
                            if Not Inc then res.Setrange("Adjusted In BC",False);
                            If Loc <> '' then res.setrange("Location Code",Loc);
                            If Res.findset then
                            begin
                                pg.SetTableView(Res);
                                Pg.RunModal();
                                CurrPage.update(false);
                             end;
                        end;            
                    end;
                }
                field("Calc Adjust Qty Required";Adjst)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 0:5;
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        Cu:Codeunit "PC Fulfilio Routines";
                        Loc:record Location;
                        Item:Record Item;
                        Res:Record "PC Fulfilo Inv. Delta Reasons";
                        Res2:Record "PC Fulfilo Inv. Delta Reasons" temporary;
                        Qty:Decimal;
                    begin
                        If Adjst <> 0 Then 
                            If Confirm('Perform The Required Qty Adjustment Now',True) then
                            begin
                                Item.Get(Rec."No.");
                                Loc.Reset;
                                Loc.Setrange("Use As In-Transit",false);
                                Loc.Setfilter(Code,'<>QC');    
                                If Loc.Findset then
                                repeat
                                    if ReasCode <> '' then
                                    begin
                                        Res.Reset;
                                        Res.SetRange(SKU,Item."No."); 
                                        Res.Setrange("Location Code",Loc.Code);
                                        if not Inc then
                                            Res.Setrange("Adjusted In BC",False);
                                        Res.Setrange("Reason Code",ReasCode);
                                        If Res.findset then
                                        repeat
                                            if Res."Adjusted Qty" <> 0 then CU.Adjust_Inventory(Item,Loc.Code,Res."Adjusted Qty",Res);
                                        until Res.Next = 0;    
                                    end
                                    else 
                                    begin
                                        Item.SetFilter("Location Filter",Loc.Code);
                                        Item.Calcfields(Inventory,"Fulfilo Inventory","Fulfilo Qty On PO");
                                        Qty := Item."Fulfilo Inventory" - (Item.Inventory + Item."Fulfilo Qty On PO");
                                        Clear(Res2);
                                        If Qty <> 0 then CU.Adjust_Inventory(Item,Loc.Code,qty,Res2);
                                    end;    
                                until Loc.Next = 0;
                            end;    
                    end;
                }
                field("MA";'Manual Adjust')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        Pg:page "PC Adjust Inventory";
                    begin
                        Pg.SetItem(rec."No.");
                        Pg.RunModal();
                        CurrPage.Update(false);
                    end;
                }

                field("Calc Adjustment Cost";Adjst * Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2:2;
                }
            }
            Group(Totals)
            {
                field("Record Count";Rec.Count)
                {
                        ApplicationArea = All;
                        Editable = false;
                }
                field("Total Adjust Costs";TotCst)
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnAssistEdit()
                    begin
                        TotCst := Calc_Adjust_Costs();
                        CurrPage.update(false);
                    end;
                }
            }                    
        }
    }
    actions
    {
        area(Processing)
        {
            action(Adjustments)
            {
                ApplicationArea = All;
                
                trigger OnAction();
                var
                    Item:record Item;
                    Loc:Record Location;
                    Qty:Decimal;
                    Cu:Codeunit "PC Fulfilio Routines";
                    win:Dialog;
                    Res:Record "PC Fulfilo Inv. Delta Reasons";
                    Res2:Record "PC Fulfilo Inv. Delta Reasons" temporary;
                 begin
                    If Confirm('Do You Wish To Make The Required Qty Adjustments For All Locations Now',True) then
                    begin
                        win.Open('Adjusting SKU #1############ For Location #2########');
                        Clear(Loc);
                        SetFilters();
                        If Rec.Findset then
                        repeat
                            Item.Get(Rec."No.");
                            Loc.Reset;
                            Loc.Setrange("Use As In-Transit",false);
                            Loc.Setfilter(Code,'<>QC');    
                            If Loc.Findset then
                            repeat
                                if ReasCode <> '' then
                                begin
                                    Res.Reset;
                                    Res.SetRange(SKU,Item."No."); 
                                    Res.Setrange("Location Code",Loc.Code);
                                    Res.Setrange("Reason Code",ReasCode);
                                    if not Inc then
                                        Res.Setrange("Adjusted In BC",False);
                                    If Res.findset then
                                    repeat
                                        if Res."Adjusted Qty" <> 0 then
                                        begin 
                                            Win.update(1,Item."No.");
                                            win.update(2,Loc.Code); 
                                            CU.Adjust_Inventory(Item,Loc.Code,Res."Adjusted Qty",Res);
                                        end;    
                                    until Res.Next = 0;    
                                end
                                else 
                                begin
                                    Item.SetFilter("Location Filter",Loc.Code);
                                    Item.Calcfields(Inventory,"Fulfilo Inventory","Fulfilo Qty On PO");
                                    Qty := Item."Fulfilo Inventory" - (Item.Inventory + Item."Fulfilo Qty On PO");
                                    If Qty <> 0 then
                                    begin
                                        Win.update(1,Item."No.");
                                        win.update(2,Loc.Code); 
                                        Clear(res2);
                                        CU.Adjust_Inventory(Item,Loc.Code,qty,res2);
                                    end;
                                end;        
                            until Loc.Next = 0;
                        until rec.next = 0;
                        win.Close();            
                    end;
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Offset := 7;    
        Clear(Supp);
        Clear(Loc);
        Clear(name);
        Clear(SkuLst);
        CLear(SKU);
        Clear(Bran);
        Clear(Branlst);
        Clear(Reason);
        Clear(ReasCode);
        Clear(Inc);
        Rec.ClearMarks();
        SetFilters();
        EnbFlg := True;
        RefMsg := 'DATA REFRESH REQUIRED';
    end;
    trigger OnAfterGetRecord()
    var
        Res:record "PC Fulfilo Inv. Delta Reasons";
    begin
        Clear(Adjst);
        if ReasCode <> '' then
        begin
            Res.Reset;
            Res.Setrange(SKU,rec."No.");
            if Loc <> '' then
                Res.Setrange("Location Code",Loc);        
            Res.Setrange("Reason Code",ReasCode);
            if not Inc then Res.Setrange("Adjusted In BC",False);
            If Res.findset then
            repeat 
                Adjst += Res."Adjusted Qty";
            until Res.Next = 0;    
        end
        else
            Adjst := rec."Fulfilo Inventory" - (rec.Inventory + rec."Fulfilo Qty On PO");
    end;
    local procedure Calc_Adjust_Costs():Decimal
    var
        totCst:Decimal;
        Res:record "PC Fulfilo Inv. Delta Reasons";
    begin
        Clear(TotCst);
        If rec.findset then
        repeat
            if ReasCode <> '' then
            begin
                Res.Reset;
                Res.Setrange(SKU,rec."No.");
                Res.Setrange("Reason Code",ReasCode);
                If Res.findset then
                repeat 
                    Totcst += ABS(Res."Adjusted Qty" * Rec."Unit Cost");
                until Res.Next = 0;    
            end
            else
                totCst += ABS((rec."Fulfilo Inventory" - (rec.Inventory + rec."Fulfilo Qty On PO")) * Rec."Unit Cost");
        until Rec.next = 0; 
        exit(Totcst);   
    end;
    local Procedure SetFilters()
    begin
        Rec.Reset;
        Rec.SetCurrentKey("Fulfilo Inventory");
        Rec.Setrange(Type,Rec.Type::Inventory);
        If Loc <> '' then rec.Setrange("Location Filter",LOC);
        If Supp <> '' then rec.SetRange("Vendor No.",SUPP);
        if Branlst <> '' Then rec.SetFilter(Brand,Branlst.Remove(Branlst.LastIndexOf('|'),1));
        If Skulst <> '' then rec.Setfilter("No.",Skulst.Remove(Skulst.LastIndexOf('|'),1));
        TotCst := Calc_Adjust_Costs();
        CurrPage.update(false);   
    end;
    local Procedure Process_Reasons()
    Var
        Res:record "PC Fulfilo Inv. Delta Reasons";
        RVal:Text;
        i:integer;
    begin
        i := Reason;
        Clear(ReasCode);
        If i > 0 then
        begin
            ReasCode := 'SA' + Format(i);
            Clear(Supp);
            Clear(name);
            Clear(SkuLst);
            CLear(SKU);
            Clear(Bran);
            Clear(Branlst);
            Rec.ClearMarks();
            SetFilters();
            if Rec.Findset then
            repeat
                Res.Reset;
                Res.Setrange(SKU,rec."No.");
                If Loc <> '' then
                    Res.SetRange("Location Code",loc);
                Res.Setrange("Reason Code",ReasCode);
                If Not Inc then
                    res.Setrange("Adjusted In BC",false);
                If Res.findset then Rec.Mark(True);
            until Rec.next = 0;
            Rec.MarkedOnly(true);
            TotCst := Calc_Adjust_Costs();
            CurrPage.Update(false);
            EnbFlg := ReasCode = '';
        end;
    end;    
    var
        Loc:code[10];
        Sku:Code[20];
        Supp:Code[20];
        Name:text;
        SkuLst:text;
        Adjst:decimal;
        Reason:Option ,"Damaged In Transit (SA1)"
                      ,"Damaged in Warehouse (SA2)"
                      ,"Receipt Error (SA3)"
                      ,"Cycle Count Variance (SA4)"
                      ,"Manufacturer Defect (SA5)"
                      ,"Re-work (SA6)"
                      ,"Consumed to packing (SA7)"
                      ,"Kitting (SA8)"
                      ,"Quarantined-non-saleable (SA9)"
                      ,"Quarantined-saleable (SA10)"
                      ,"Quarantined on Receipt (SA11)";
        ReasCode:Code[5];
        TotCst:Decimal;
        EnbFlg:Boolean;
        Offset:Integer;
        Bran:Code[30];
        Branlst:text;
        Inc:Boolean;
        RefMsg:Text;
            
}