page 80010 "PC Shopify Item Maintenance"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Item;  
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Caption = 'Shopify Item Maintenance';
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            Group(Filter)
            {
                field("Maintence Mode";mode)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    trigger OnValidate()
                    begin 
                        SetFilters();      
                    end;
                }
                field("Shopify Type";Stype)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    trigger OnValidate()
                    begin 
                        SetFilters();      
                    end;
                }
                field("SKU Filter";Sku)
                {
                    ApplicationArea = all;
                    Style = Strong;
                    TableRelation = Item where("Is Child Flag"=Const(False));
                    trigger OnValidate()
                    begin 
                        SetFilters();      
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(SKU);
                        SetFilters();         
                    end;
                }
            }
            repeater(GroupName)
            {
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        Pg:page "Item Card";
                        Item:Record Item;
                    begin
                        Item.Get(rec."No.");    
                        pg.SetRecord(Item);
                        Pg.RunModal();
                    end;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Msg)
            {
                Visible = Mode = Mode::Deletions;
                ApplicationArea = All;
                Caption = 'Shopify Deletions';
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Shopify Routines";
                    Win:Dialog;
                    Temp:Record Item temporary;
                    Rel:Record "PC Shopify Item Relations";
                begin
                    If Mode = Mode::Deletions then
                    begin 
                        If Confirm('Are You Sure You Wish To Delete All Marked Items From Shopify Now?',True) then
                        begin
                            Win.Open('Removing Shopify Item #1##############');
                            SetFilters();
                            CurrPage.SetSelectionFilter(rec);
                            temp.DeleteAll(False);
                            If rec.findSet then
                            repeat
                                Rel.Reset;
                                Rel.Setrange("Child Item No.",Rec."No.");
                                if Not Rel.FindSet then
                                Begin   
                                    temp.Copy(Rec);
                                    Temp.insert(false);
                                end;    
                            until rec.Next = 0; 
                            Temp.Reset;        
                            If Temp.Findset then
                            repeat
                                Win.update(1,Temp."No.");
                                Cu.Delete_Items(Temp."No.",false);  
                            until Temp.Next = 0
                            else
                                Message('Nothing Found Marked for Removal');
                            SetFilters();
                            win.Close();    
                        end;
                    end;
                end;    
            }
            action(Msg1)
            {
                Visible = Mode = Mode::Additions;
                ApplicationArea = All;
                Caption = 'Shopify Additions';
                Promoted = true;
                PromotedIsBig = True;
                trigger OnAction();
                var
                    Cu:Codeunit "PC Shopify Routines";
                    Win:Dialog;
                    Temp:Record Item temporary;
                begin
                    if Mode = Mode::Additions then
                    begin
                        If Confirm('Are You Sure You Wish To Add All Marked Items Into Shopify Now?',True) then
                        begin
                            Win.Open('Adding Shopify Item #1##############');
                            SetFilters();
                            CurrPage.SetSelectionFilter(rec);
                            temp.DeleteAll(False);
                            If rec.findSet then
                            repeat
                                If Rec."Shopify Item" <> Rec."Shopify Item"::Shopify then
                                begin
                                    Rec."Shopify Item" := Rec."Shopify Item"::Shopify;
                                    Rec.modify;
                                end;    
                                temp.Copy(Rec);
                                Temp.insert(false);
                            until rec.Next = 0;
                            Temp.Reset;         
                            If Temp.Findset then
                            repeat
                                Win.update(1,Temp."No.");
                                Cu.Process_Items(Temp."No.",false);  
                            until temp.Next = 0
                            else
                                Message('Nothing Found Marked For Addition');
                            win.close;    
                            SetFilters();
                        end;
                    end;
                end;    
            }
       }
    }
    
    trigger OnOpenPage()
    begin
        SetFilters();
    end;
    var
        SType:Option All,Parent,Standalone;
        Mode:Option Additions,Deletions;
        Sku:Code[20];

    local Procedure SetFilters()
    begin
        rec.Reset;
        If Mode = Mode::Additions then
        begin
            rec.Setrange("Shopify Product ID",0);
            rec.Setrange("Shopify Product Variant ID",0);
            rec.Setrange("Is In Shopify Flag",False);
            rec.Setrange("Is Child Flag",false);
            rec.Setrange("Shopify Item",rec."Shopify Item"::Shopify);
            rec.SetFilter("Shopify Title",'<>%1',' '); 
        end
        else 
        begin
            rec.SetFilter("Shopify Product ID",'>0');
            rec.Setrange("Is In Shopify Flag",true);
            rec.Setrange("Is Child Flag",false);
        end;    
        If SType = SType::Parent then
            rec.Setrange(Type,rec.Type::"Non-Inventory")
        else if SType = SType::Standalone then
           rec.Setrange(Type,rec.Type::"Inventory");
        If Sku <> '' then rec.Setrange("No.",Sku);  
        CurrPage.update(false);   
    end;
        
}