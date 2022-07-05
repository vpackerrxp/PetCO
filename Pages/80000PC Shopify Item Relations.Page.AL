page 80000 "PC Shopify Item Relations"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Shopify Item Relations";
    Caption = 'Shopify Parent/Child';
    layout
    {
        area(Content)
        {
            group(Hdr)
            {
                ShowCaption = false;
                field("Parent Item"; Item."No.")
                {
                    Caption = 'Parent Item';    
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Item.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            repeater(GroupName)
            {
                field("Item Variant"; rec."Child Item No.")
                {
                    ApplicationArea = All;
                    TableRelation = Item."No." WHERE (Type=CONST(Inventory),"Shopify Item"=CONST(Shopify),"Shopify Product ID"=Const(0));
                    trigger OnDrillDown()
                    var
                        Item:Record Item;
                        Pg:page "Item Card";
                    begin
                        Item.Setrange("No.",rec."Child Item No.");
                        Pg.SetTableView(Item);   
                        Pg.RunModal();   
                    end;
                }
                field(CDescription; rec."Child Description")
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field("Child Position";rec."Child Position" )
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Child List Postion';
                }
                field("Un Publish Child";rec."Un Publish Child" )
                {
                    ApplicationArea = All;
                    Caption = 'Un Published Status';
                    Enabled = Pub;
                }

            }
        }
    }
    actions
    {
        Area(Processing)
        {
            action("Edit Publish")
            {
                ApplicationArea = all;
                trigger OnAction()
                Begin
                    Pub := Confirm('Allow Publish Edit',True);
                    CurrPage.update(false);
                end;     
            }
        }
    }
  
    trigger OnOpenPage()
    begin
        rec.Setrange("Parent Item No.",Item."No.");
        Pub := false;
    end;
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Currpage.update(true);
    end;
    var 
       Item :Record Item;
       Pub:Boolean;
    procedure SetParent(ItemNo:Code[20])
    begin
        Item.Get(ItemNo);
    end;    
 
}