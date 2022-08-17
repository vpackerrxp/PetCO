page 80011 "PC Supplier Brand Rebates"
{
    Caption = 'Supplier Brand Rebates';
    PageType = Worksheet;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Supplier Brand Rebates";
    InsertAllowed = false;
    //DeleteAllowed = false;
    Editable = true;
    
    layout
    {
        area(Content)
        {
            Group(Filters)
            {
                field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Visible = SuppFlg; 
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Clear(Supp);
                        Vend.reset;
                        Vend.Setfilter("No.",'SUP-*');
                        If Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                Supp := Vend."No.";      
                           end;
                        end;
                        SetFilters();
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        SetFilters();
                    end;
                }
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
                            Bran := rel.Brand;
                            SetFilters();
                        end;      
                    end; 
                    trigger OnAssistEdit()
                    begin
                        Clear(Bran);
                        SetFilters();
                    end;
                }
                field("Rebate Status Filter"; Stat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Visible = Mode = Mode::"Purch Rebates";
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
                field("A";'Close Rebate Period')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    Visible = Mode = Mode::"Purch Rebates";
                    trigger OnDrillDown()
                    var
                        Reb:record "PC Supplier Brand Rebates";
                    begin
                       If Confirm('Are You Sure You Wish To Close This Rebate Period Now?', True) then
                        begin
                            rec.Reset;
                            rec.Setrange("Rebate Status",rec."Rebate Status"::Open);
                            rec.Setfilter("Rebate Start Date Period",'<%1',Today);
                            if rec.Findset then
                            begin
                                repeat
                                    rec."Rebate End Date Period" := Today;
                                    rec."Rebate Status" := rec."Rebate Status"::Closed;
                                    rec.Modify(False);
                                until rec.Next = 0;    
                                Commit;
                                rec.Reset;
                                rec.Setrange("Rebate Status",rec."Rebate Status"::Closed);
                                rec.SetRange("Rebate End Date Period",Today);
                                If rec.Findset then
                                repeat
                                    Reb.Copy(rec);
                                    Clear(Reb."Rebate End Date Period");
                                    Clear(Reb."Rebate Status");
                                    Reb."Rebate Start Date Period" := TODAY;
                                    Reb.insert(false);   
                                until rec.Next = 0;
                            end
                            else
                                Message('Closure is not possible');   
                            SetFilters();    
                      end;            
                   end;    
                }
            }    
            repeater(Group)
            {
                field("Supplier No."; rec."Supplier No.")
                {
                    ApplicationArea = All;
                }
                field("Rebate Supplier No.";rec."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                }
                field(Brand; rec.Brand)
                {
                    ApplicationArea = All;
                }
                field("Volume Rebate %"; rec."Volume Rebate %")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Purch Rebates";
                }
                field("Marketing Rebate %"; rec."Marketing Rebate %")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Purch Rebates";
                }
                field("Supply Chain Rebate %"; rec."Supply Chain Rebate %")
                {
                   ApplicationArea = All;
                   Visible = Mode = Mode::"Purch Rebates";
                }

                field("Auto Order Rebate %"; rec."Auto Order Rebate %")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Auto Order";
                }
                field("Palatability Rebate %"; rec."Palatability Rebate %")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::Palatability;
                }
                field("PO Line Disc %"; rec."PO Line Disc %")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::PO;
                }
                field("Rebate Start Date Period"; rec."Rebate Start Date Period")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Purch Rebates";
                }
                field("Rebate End Date Period"; rec."Rebate End Date Period")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Purch Rebates";
                }
                field("Rebate Status"; rec."Rebate Status")
                {
                    ApplicationArea = All;
                    Visible = Mode = Mode::"Purch Rebates";
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Auto Update")
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    Ven:Record Vendor;
                    Item:Record Item;
                    SupReb:Record "PC Supplier Brand Rebates";
                    ItemVen:Record "Item Vendor";
                    win:dialog;
                    Dat:date;
                begin
                    If Confirm('Auto Update List Now?',True) then
                    begin
                        Win.open('Adding Supplier #1############\'
                                +'Brand           #2###################');

                        dat := Today;
                        SupReb.Reset();
                        SupReb.Setrange("Rebate Status",SupReb."Rebate Status"::Open);
                        if SupReb.Findset then Dat := SupReb."Rebate Start Date Period";
                        Ven.Reset;
                        Ven.SetFilter("No.",'SUP-*');
                        If Ven.Findset then
                        repeat
                            Item.Reset;
                            Item.Setrange("Vendor No.",Ven."No.");
                            Item.Setrange(Type,Item.Type::Inventory);
                            If Item.Findset then
                            repeat
                                If not SupReb.Get(Ven."No.",Item.Brand,Dat) then
                                begin
                                    Win.update(1,Ven."No.");
                                    Win.Update(2,Item.Brand);
                                    SupReb.init;
                                    SupReb."Supplier No." := Ven."No.";
                                    SupReb."Rebate Supplier No." := Ven."No.";   
                                    SupReb.Brand := Item.Brand;
                                    SupReb."Rebate Start Date Period" := Dat;
                                    SupReb."Rebate Status" := SupReb."Rebate Status"::Open;
                                    SupReb.Insert;
                                end;
                            until Item.Next = 0;
                        until Ven.next = 0;
                        ItemVen.Reset;
                       if ItemVen.findset then
                        repeat
                            Item.Get(ItemVen."Item No.");
                            iF Item."Vendor No." <> '' then
                            begin
                                If not SupReb.Get(ItemVen."Vendor No.",Item.Brand,dat) then
                                begin
                                    Win.update(1,ItemVen."Vendor No.");
                                    Win.Update(2,Item.Brand);
                                    SupReb.init;
                                    SupReb."Supplier No." := ItemVen."Vendor No.";   
                                    SupReb."Rebate Supplier No." := ItemVen."Vendor No.";   
                                    SupReb.Brand := Item.Brand;
                                    SupReb."Rebate Start Date Period" := Dat;
                                    SupReb."Rebate Status" := SupReb."Rebate Status"::Open;
                                    SupReb.Insert;
                                end;
                            end;    
                        until ItemVen.Next = 0;
                        win.close;
                    end;                        
                end;
            }
        }
    }
    
    procedure Set_Page_Mode(PMode:option;Ven:code[20])
    begin
        Mode := Pmode;
        If Mode <> Mode::"Purch Rebates" then Stat := Stat::Open;
        Supp :=  Ven;
        Suppflg := Supp = '';
    end;
    local Procedure SetFilters()
    begin
        rec.Reset;
        If Supp <> '' then rec.Setrange("Supplier No.",Supp);
        If Bran <> '' Then rec.Setrange(Brand,Bran);
        If Stat <> Stat::All then rec.Setrange("Rebate Status",Stat - 1);
        CurrPage.update(false);
    end;
    trigger OnOpenPage()
    begin
        SetFilters();
    end;
    trigger OnAfterGetRecord()
    Begin
        If (Rec."Supplier No." <> '') and (Rec."Rebate Supplier No." = '') then
        begin
            Rec."Rebate Supplier No." := Rec."Supplier No.";
            Rec.Modify();
        end;
    End;

    Var
        Supp:Code[20];
        Bran:Code[30];
        Stat:Option All,Open,Closed;  
        RebType: Option All,Vol,Mark,Supp;
        Mode:option "Purch Rebates","Auto Order",Palatability,PO;
        SuppFlg:boolean;

}