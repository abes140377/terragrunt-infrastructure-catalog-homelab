package provider

import (
    "context"
    "fmt"

    "github.com/hashicorp/terraform-plugin-framework/path"
    "github.com/hashicorp/terraform-plugin-framework/resource"
    "github.com/hashicorp/terraform-plugin-framework/resource/schema"
    "github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
    "github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
    "github.com/hashicorp/terraform-plugin-framework/types"
    "github.com/hashicorp/terraform-plugin-log/tflog"

    "terraform-provider-company/internal/provider/client"
)

var _ resource.Resource = &CMDBEntryResource{}
var _ resource.ResourceWithImportState = &CMDBEntryResource{}

func NewCMDBEntryResource() resource.Resource {
    return &CMDBEntryResource{}
}

type CMDBEntryResource struct {
    client *client.CMDBClient
}

type CMDBEntryResourceModel struct {
    ID          types.String `tfsdk:"id"`
    Name        types.String `tfsdk:"name"`
    Environment types.String `tfsdk:"environment"`
    Application types.String `tfsdk:"application"`
    Status      types.String `tfsdk:"status"`
}

func (r *CMDBEntryResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
    resp.TypeName = req.ProviderTypeName + "_cmdb_entry"
}

func (r *CMDBEntryResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "CMDB entry for virtual machines",
        Attributes: map[string]schema.Attribute{
            "id": schema.StringAttribute{
                Description: "CMDB entry ID",
                Computed:    true,
                PlanModifiers: []planmodifier.String{
                    stringplanmodifier.UseStateForUnknown(),
                },
            },
            "name": schema.StringAttribute{
                Description: "VM name",
                Required:    true,
            },
            "environment": schema.StringAttribute{
                Description: "Environment",
                Required:    true,
            },
            "application": schema.StringAttribute{
                Description: "Application name",
                Required:    true,
            },
            "status": schema.StringAttribute{
                Description: "VM status",
                Computed:    true,
            },
        },
    }
}

func (r *CMDBEntryResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
    if req.ProviderData == nil {
        return
    }

    client, ok := req.ProviderData.(*client.CMDBClient)
    if !ok {
        resp.Diagnostics.AddError(
            "Unexpected Resource Configure Type",
            fmt.Sprintf("Expected *client.CMDBClient, got: %T", req.ProviderData),
        )
        return
    }

    r.client = client
}

func (r *CMDBEntryResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
    var data CMDBEntryResourceModel

    resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    tflog.Info(ctx, "Creating CMDB entry", map[string]any{"name": data.Name.ValueString()})

    // CMDB API Call
    entry, err := r.client.CreateEntry(ctx, client.CMDBEntry{
        Name:        data.Name.ValueString(),
        Environment: data.Environment.ValueString(),
        Application: data.Application.ValueString(),
    })

    if err != nil {
        resp.Diagnostics.AddError("Error creating CMDB entry", err.Error())
        return
    }

    data.ID = types.StringValue(entry.ID)
    data.Status = types.StringValue(entry.Status)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *CMDBEntryResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
    var data CMDBEntryResourceModel

    resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    entry, err := r.client.GetEntry(ctx, data.ID.ValueString())
    if err != nil {
        resp.Diagnostics.AddError("Error reading CMDB entry", err.Error())
        return
    }

    data.Status = types.StringValue(entry.Status)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *CMDBEntryResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
    var data CMDBEntryResourceModel

    resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    entry, err := r.client.UpdateEntry(ctx, data.ID.ValueString(), client.CMDBEntry{
        Name:        data.Name.ValueString(),
        Environment: data.Environment.ValueString(),
        Application: data.Application.ValueString(),
    })

    if err != nil {
        resp.Diagnostics.AddError("Error updating CMDB entry", err.Error())
        return
    }

    data.Status = types.StringValue(entry.Status)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *CMDBEntryResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
    var data CMDBEntryResourceModel

    resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    err := r.client.DeleteEntry(ctx, data.ID.ValueString())
    if err != nil {
        resp.Diagnostics.AddError("Error deleting CMDB entry", err.Error())
        return
    }
}

func (r *CMDBEntryResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
    resource.ImportStatePassthroughID(ctx, path.Root("id"), req, resp)
}
