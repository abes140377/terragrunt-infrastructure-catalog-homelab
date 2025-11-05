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
