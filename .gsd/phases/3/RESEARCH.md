# Phase 3 Research: PSN Media API

## API Endpoint
```
GET https://m.np.playstation.com/api/gameMediaService/v2/c2s/category/cloudMediaGallery/ugcType/all
```

## Authentication
- Requires Bearer token in Authorization header
- Use access_token from Phase 1/2 auth flow

## Response Structure
Based on existing code (`old/server/psn-types.py`):

```json
{
  "ugcDocument": [
    {
      "id": "string",
      "title": "string",
      "scePlatform": "string (PS4/PS5)",
      "sceTitleId": "string",
      "sceTitleName": "string (game name)",
      "videoDuration": float | null,
      "uploadDate": "string (ISO date)",
      "ugcType": int (1=screenshot, 2=video),
      "titleImageUrl": "string",
      "largePreviewImage": "string",
      "smallPreviewImage": "string",
      "fileType": "string",
      "fileSize": int,
      "resolution": "string",
      "videoUrl": "string | null",
      "screenshotUrl": "string | null",
      "downloadUrl": "string | null"
      // ... other metadata fields
    }
  ],
  "nextCursorMark": "string (for pagination)",
  "limit": int
}
```

## Key Fields for UI
- `smallPreviewImage` / `largePreviewImage` — Thumbnails
- `sceTitleName` — Game name
- `uploadDate` — When captured
- `ugcType` — 1=screenshot, 2=video
- `videoDuration` — For video length display
- `resolution` — 1080p, 4K, etc.
- `fileSize` — For download info

## Pagination
- Response includes `nextCursorMark` for cursor-based pagination
- Pass as query param for next page

## Implementation Notes
- Use `cached_network_image` for efficient thumbnail loading
- Implement infinite scroll with cursor pagination
- Show video icon overlay for ugcType=2
- Display game name and date as metadata
