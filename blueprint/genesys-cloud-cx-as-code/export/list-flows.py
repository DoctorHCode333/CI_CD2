#!/usr/bin/env python3
"""
List all Genesys Cloud flows in the environment to verify flow names and permissions
"""
import os
import sys

try:
    import PureCloudPlatformClientV2
    from PureCloudPlatformClientV2.rest import ApiException
except ImportError:
    print("ERROR: PureCloudPlatformClientV2 not installed!")
    print("Install with: pip install PureCloudPlatformClientV2")
    sys.exit(1)

def main():
    # Check credentials
    client_id = os.environ.get('GENESYSCLOUD_OAUTHCLIENT_ID')
    client_secret = os.environ.get('GENESYSCLOUD_OAUTHCLIENT_SECRET')
    region = os.environ.get('GENESYSCLOUD_REGION', 'us-west-2')  # Default to DEV environment
    
    if not client_id or not client_secret:
        print("ERROR: Missing credentials!")
        print("Set GENESYSCLOUD_OAUTHCLIENT_ID and GENESYSCLOUD_OAUTHCLIENT_SECRET")
        print("\nFor DEV environment (where HarshTestFlow exists):")
        print("  export GENESYSCLOUD_REGION=us-west-2")
        print("  export GENESYSCLOUD_API_REGION=https://api.usw2.pure.cloud")
        sys.exit(1)
    
    print(f"=== Connecting to Genesys Cloud ({region}) ===\n")
    
    try:
        # Configure SDK
        region_host = getattr(PureCloudPlatformClientV2.PureCloudRegionHosts, region.replace('-', '_'))
        PureCloudPlatformClientV2.configuration.host = region_host.get_api_host()
        
        # Authenticate
        api_client = PureCloudPlatformClientV2.api_client.ApiClient().get_client_credentials_token(
            client_id,
            client_secret
        )
        
        print(f"✓ Authentication successful!\n")
        
        # First, list divisions to check access
        print("=== Checking Division Access ===")
        auth_api = PureCloudPlatformClientV2.AuthorizationApi(api_client)
        try:
            divisions = auth_api.get_authorization_divisions(page_size=100)
            print(f"Divisions accessible: {divisions.total}")
            home_division_id = None
            for div in divisions.entities:
                home_marker = " (HOME)" if div.home_division else ""
                print(f"  - {div.name}{home_marker} (ID: {div.id})")
                if div.home_division:
                    home_division_id = div.id
            print()
        except ApiException as e:
            print(f"  Warning: Could not list divisions: {e.status}")
            print()
        
        # List flows
        architect_api = PureCloudPlatformClientV2.ArchitectApi(api_client)
        
        print("=== Fetching all flows ===")
        
        # First try without division filter
        flows = architect_api.get_flows(page_size=100, page_number=1)
        
        print(f"Total flows found (all divisions): {flows.total}\n")
        
        if flows.total == 0:
            print("WARNING: No flows found! This could indicate a permission issue.")
            print("Ensure your OAuth client has 'architect' and 'architect:readonly' scopes.\n")
            
            # Try to get flows from Home division specifically
            print("=== Trying to fetch flows from Home division specifically ===")
            try:
                if home_division_id:
                    flows_home = architect_api.get_flows(page_size=100, page_number=1, division_id=[home_division_id])
                    print(f"Flows in Home division: {flows_home.total}")
                    flows = flows_home
            except Exception as e:
                print(f"  Error fetching Home division flows: {e}")
        
        # Search for specific patterns
        print("=== Flows containing 'CI_CD', 'Test', 'BFSI', or 'Harsh' ===")
        matching_flows = []
        for flow in flows.entities:
            name_lower = flow.name.lower()
            if any(term in name_lower for term in ['ci_cd', 'test', 'bfsi', 'harsh']):
                matching_flows.append(flow)
                print(f"  ✓ Name: '{flow.name}'")
                print(f"    Type: {flow.type}")
                print(f"    ID: {flow.id}")
                division_name = flow.division.name if hasattr(flow, 'division') and flow.division else 'Unknown'
                print(f"    Division: {division_name}")
                print(f"    Published: {flow.published if hasattr(flow, 'published') else 'N/A'}")
                print()
        
        if not matching_flows:
            print("  No matching flows found.\n")
        
        # Show all flows with division info
        print("=== All Flows in Environment ===")
        for i, flow in enumerate(flows.entities, 1):
            status = "📗 Published" if (hasattr(flow, 'published') and flow.published) else "📕 Draft"
            division_name = flow.division.name if hasattr(flow, 'division') and flow.division else 'Unknown'
            print(f"{i:3}. {status} | {flow.type:15} | [{division_name}] {flow.name}")
        
        # Check for additional pages
        if flows.page_count and flows.page_count > 1:
            print(f"\n(Showing page 1 of {flows.page_count})")
            # Fetch all pages
            print("\n=== Fetching all pages ===")
            all_flows = list(flows.entities)
            for page in range(2, flows.page_count + 1):
                more_flows = architect_api.get_flows(page_size=100, page_number=page)
                all_flows.extend(more_flows.entities)
                print(f"  Fetched page {page}/{flows.page_count}")
            
            # Search in all flows
            print(f"\nTotal flows across all pages: {len(all_flows)}")
            for flow in all_flows:
                if 'harsh' in flow.name.lower():
                    division_name = flow.division.name if hasattr(flow, 'division') and flow.division else 'Unknown'
                    print(f"  ✓ Found: '{flow.name}' in division '{division_name}'")
        
        # Verify specific flow
        print("\n=== Verifying Flow: 'HarshTestFlow' ===")
        found = False
        all_flow_entities = flows.entities if not (flows.page_count and flows.page_count > 1) else all_flows
        for flow in all_flow_entities:
            if flow.name == "HarshTestFlow":
                found = True
                print(f"✓ FOUND: '{flow.name}'")
                print(f"  Type: {flow.type}")
                print(f"  ID: {flow.id}")
                division_name = flow.division.name if hasattr(flow, 'division') and flow.division else 'Unknown'
                print(f"  Division: {division_name}")
                published_status = flow.published if hasattr(flow, 'published') else False
                print(f"  Published: {published_status}")
                print(f"\n  → Use in export: genesyscloud_flow::HarshTestFlow")
                break
        
        if not found:
            print("✗ Flow 'HarshTestFlow' NOT FOUND!")
            print("\n=== Searching with name filter ===")
            try:
                # Try direct name search
                search_result = architect_api.get_flows(name="HarshTestFlow")
                if search_result.total > 0:
                    print(f"✓ Found via name filter: {search_result.entities[0].name}")
                    flow = search_result.entities[0]
                    division_name = flow.division.name if hasattr(flow, 'division') and flow.division else 'Unknown'
                    print(f"  Division: {division_name}")
                    print(f"  ID: {flow.id}")
                else:
                    print("  Not found via name filter either")
            except Exception as e:
                print(f"  Name filter search failed: {e}")
            
            print("\nPossible reasons:")
            print("  1. Flow doesn't exist in this environment")
            print("  2. Flow has a different name (check list above)")
            print("  3. OAuth client lacks permission to view this flow")
            print("\nSuggested actions:")
            print("  - Create a flow named 'HarshTestFlow' in Genesys Cloud")
            print("  - Or update export config to use an existing flow name from the list above")
        
    except ApiException as e:
        print(f"\n✗ API ERROR!")
        print(f"Status: {e.status}")
        print(f"Reason: {e.reason}")
        print(f"Body: {e.body}")
        
        if e.status == 401:
            print("\n→ Authentication failed. Check your OAuth credentials.")
        elif e.status == 403:
            print("\n→ Permission denied. Ensure OAuth client has these scopes:")
            print("   - architect")
            print("   - architect:readonly")
        
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ ERROR: {type(e).__name__}")
        print(f"{e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
