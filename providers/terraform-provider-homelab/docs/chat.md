Hier ist ein vollständiges Grundgerüst für einen Custom Provider in Go:

## Projektstruktur

```
terraform-provider-company/
├── main.go
├── go.mod
├── internal/
│   └── provider/
│       ├── provider.go
│       ├── data_source_naming.go
│       ├── resource_cmdb_entry.go
│       └── client/
│           └── cmdb_client.go
├── examples/
│   └── main.tf
└── docs/
```

## 1. main.go

```go
package main

import (
    "context"
    "flag"
    "log"

    "github.com/hashicorp/terraform-plugin-framework/providerserver"
    "terraform-provider-company/internal/provider"
)

var (
    version string = "dev"
)

func main() {
    var debug bool

    flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers")
    flag.Parse()

    opts := providerserver.ServeOpts{
        Address: "registry.terraform.io/yourcompany/company",
        Debug:   debug,
    }

    err := providerserver.Serve(context.Background(), provider.New(version), opts)
    if err != nil {
        log.Fatal(err.Error())
    }
}
```

## 2. go.mod

```go
module terraform-provider-company

go 1.21

require (
    github.com/hashicorp/terraform-plugin-framework v1.4.2
    github.com/hashicorp/terraform-plugin-log v0.9.0
)
```

## 3. internal/provider/provider.go

```go
package provider

import (
    "context"
    "os"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/provider"
    "github.com/hashicorp/terraform-plugin-framework/provider/schema"
    "github.com/hashicorp/terraform-plugin-framework/resource"
    "github.com/hashicorp/terraform-plugin-framework/types"

    "terraform-provider-company/internal/provider/client"
)

var _ provider.Provider = &CompanyProvider{}

type CompanyProvider struct {
    version string
}

type CompanyProviderModel struct {
    CMDBEndpoint types.String `tfsdk:"cmdb_endpoint"`
    CMDBToken    types.String `tfsdk:"cmdb_token"`
}

func New(version string) func() provider.Provider {
    return func() provider.Provider {
        return &CompanyProvider{
            version: version,
        }
    }
}

func (p *CompanyProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
    resp.TypeName = "company"
    resp.Version = p.version
}

func (p *CompanyProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Provider for company VM naming and CMDB integration",
        Attributes: map[string]schema.Attribute{
            "cmdb_endpoint": schema.StringAttribute{
                Description: "CMDB API endpoint URL",
                Optional:    true,
            },
            "cmdb_token": schema.StringAttribute{
                Description: "CMDB API authentication token",
                Optional:    true,
                Sensitive:   true,
            },
        },
    }
}

func (p *CompanyProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
    var config CompanyProviderModel

    resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Fallback auf Environment Variables
    endpoint := os.Getenv("CMDB_ENDPOINT")
    token := os.Getenv("CMDB_TOKEN")

    if !config.CMDBEndpoint.IsNull() {
        endpoint = config.CMDBEndpoint.ValueString()
    }

    if !config.CMDBToken.IsNull() {
        token = config.CMDBToken.ValueString()
    }

    if endpoint == "" {
        resp.Diagnostics.AddError(
            "Missing CMDB Endpoint",
            "The provider requires a CMDB endpoint. Set it via provider config or CMDB_ENDPOINT environment variable.",
        )
        return
    }

    // CMDB Client initialisieren
    cmdbClient := client.NewCMDBClient(endpoint, token)

    resp.DataSourceData = cmdbClient
    resp.ResourceData = cmdbClient
}

func (p *CompanyProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
    return []func() datasource.DataSource{
        NewNamingDataSource,
    }
}

func (p *CompanyProvider) Resources(ctx context.Context) []func() resource.Resource {
    return []func() resource.Resource{
        NewCMDBEntryResource,
    }
}
```

## 4. internal/provider/data_source_naming.go

```go
package provider

import (
    "context"
    "fmt"
    "strings"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/datasource/schema"
    "github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = &NamingDataSource{}

func NewNamingDataSource() datasource.DataSource {
    return &NamingDataSource{}
}

type NamingDataSource struct{}

type NamingDataSourceModel struct {
    Environment types.String `tfsdk:"environment"`
    Application types.String `tfsdk:"application"`
    Instance    types.String `tfsdk:"instance"`
    Region      types.String `tfsdk:"region"`
    VMName      types.String `tfsdk:"vm_name"`
}

func (d *NamingDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
    resp.TypeName = req.ProviderTypeName + "_naming"
}

func (d *NamingDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Generates VM names according to company naming convention",
        Attributes: map[string]schema.Attribute{
            "environment": schema.StringAttribute{
                Description: "Environment (dev, test, prod)",
                Required:    true,
            },
            "application": schema.StringAttribute{
                Description: "Application name",
                Required:    true,
            },
            "instance": schema.StringAttribute{
                Description: "Instance number",
                Required:    true,
            },
            "region": schema.StringAttribute{
                Description: "Region code",
                Optional:    true,
            },
            "vm_name": schema.StringAttribute{
                Description: "Generated VM name",
                Computed:    true,
            },
        },
    }
}

func (d *NamingDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
    var data NamingDataSourceModel

    resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Hier Ihre Naming-Logik implementieren
    vmName := d.generateVMName(
        data.Environment.ValueString(),
        data.Application.ValueString(),
        data.Instance.ValueString(),
        data.Region.ValueString(),
    )

    data.VMName = types.StringValue(vmName)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (d *NamingDataSource) generateVMName(env, app, instance, region string) string {
    // Beispiel Naming Convention: <env>-<region>-<app>-<instance>
    // z.B.: prod-eu-webapp-001

    parts := []string{}

    if env != "" {
        parts = append(parts, strings.ToLower(env))
    }

    if region != "" {
        parts = append(parts, strings.ToLower(region))
    }

    if app != "" {
        parts = append(parts, strings.ToLower(app))
    }

    if instance != "" {
        parts = append(parts, fmt.Sprintf("%03s", instance))
    }

    return strings.Join(parts, "-")
}
```

## 5. internal/provider/resource_cmdb_entry.go

```go
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
```

## 6. internal/provider/client/cmdb_client.go

```go
package client

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
)

type CMDBClient struct {
    endpoint   string
    token      string
    httpClient *http.Client
}

type CMDBEntry struct {
    ID          string `json:"id,omitempty"`
    Name        string `json:"name"`
    Environment string `json:"environment"`
    Application string `json:"application"`
    Status      string `json:"status,omitempty"`
}

func NewCMDBClient(endpoint, token string) *CMDBClient {
    return &CMDBClient{
        endpoint:   endpoint,
        token:      token,
        httpClient: &http.Client{},
    }
}

func (c *CMDBClient) CreateEntry(ctx context.Context, entry CMDBEntry) (*CMDBEntry, error) {
    body, err := json.Marshal(entry)
    if err != nil {
        return nil, err
    }

    req, err := http.NewRequestWithContext(ctx, "POST", c.endpoint+"/api/vms", bytes.NewBuffer(body))
    if err != nil {
        return nil, err
    }

    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+c.token)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
        bodyBytes, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("CMDB API error: %d - %s", resp.StatusCode, string(bodyBytes))
    }

    var created CMDBEntry
    if err := json.NewDecoder(resp.Body).Decode(&created); err != nil {
        return nil, err
    }

    return &created, nil
}

func (c *CMDBClient) GetEntry(ctx context.Context, id string) (*CMDBEntry, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", c.endpoint+"/api/vms/"+id, nil)
    if err != nil {
        return nil, err
    }

    req.Header.Set("Authorization", "Bearer "+c.token)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("CMDB API error: %d", resp.StatusCode)
    }

    var entry CMDBEntry
    if err := json.NewDecoder(resp.Body).Decode(&entry); err != nil {
        return nil, err
    }

    return &entry, nil
}

func (c *CMDBClient) UpdateEntry(ctx context.Context, id string, entry CMDBEntry) (*CMDBEntry, error) {
    body, err := json.Marshal(entry)
    if err != nil {
        return nil, err
    }

    req, err := http.NewRequestWithContext(ctx, "PUT", c.endpoint+"/api/vms/"+id, bytes.NewBuffer(body))
    if err != nil {
        return nil, err
    }

    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+c.token)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("CMDB API error: %d", resp.StatusCode)
    }

    var updated CMDBEntry
    if err := json.NewDecoder(resp.Body).Decode(&updated); err != nil {
        return nil, err
    }

    return &updated, nil
}

func (c *CMDBClient) DeleteEntry(ctx context.Context, id string) error {
    req, err := http.NewRequestWithContext(ctx, "DELETE", c.endpoint+"/api/vms/"+id, nil)
    if err != nil {
        return err
    }

    req.Header.Set("Authorization", "Bearer "+c.token)

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
        return fmt.Errorf("CMDB API error: %d", resp.StatusCode)
    }

    return nil
}
```

## 7. examples/main.tf

```hcl
terraform {
  required_providers {
    company = {
      source = "yourcompany/company"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

provider "company" {
  cmdb_endpoint = "https://cmdb.company.com"
  cmdb_token    = var.cmdb_token
}

# Name generieren
data "company_naming" "webapp" {
  environment = "prod"
  application = "webapp"
  instance    = "001"
  region      = "eu"
}

# CMDB Eintrag erstellen
resource "company_cmdb_entry" "webapp" {
  name        = data.company_naming.webapp.vm_name
  environment = "prod"
  application = "webapp"
}

# VM erstellen
resource "vsphere_virtual_machine" "webapp" {
  name = data.company_naming.webapp.vm_name

  # ... weitere vSphere Konfiguration

  depends_on = [company_cmdb_entry.webapp]
}

output "vm_name" {
  value = data.company_naming.webapp.vm_name
}
```

## Build und Installation

```bash
# Dependencies installieren
go mod tidy

# Provider bauen
go build -o terraform-provider-company

# Lokal installieren für Tests
mkdir -p ~/.terraform.d/plugins/yourcompany.com/company/company/0.1.0/linux_amd64/
cp terraform-provider-company ~/.terraform.d/plugins/yourcompany.com/company/company/0.1.0/linux_amd64/

# In examples/ Verzeichnis testen
cd examples
terraform init
terraform plan
```

## Nächste Schritte

1. **Naming-Logik implementieren** in `generateVMName()`
2. **CMDB API anpassen** in `cmdb_client.go` an Ihre tatsächliche API
3. **Tests schreiben** mit dem Terraform Plugin Testing Framework
4. **Dokumentation** in `docs/` Verzeichnis hinzufügen
5. **CI/CD Pipeline** für automatische Builds und Releases

Haben Sie Fragen zu bestimmten Teilen des Codes?
