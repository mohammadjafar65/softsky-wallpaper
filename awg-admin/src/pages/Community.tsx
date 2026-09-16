import { useEffect, useState, useMemo } from 'react';
import toast from 'react-hot-toast';
import {
  AlertTriangle,
  CheckCircle2,
  Eye,
  EyeOff,
  ExternalLink,
  Heart,
  Image as ImageIcon,
  MessageCircle,
  RefreshCw,
  Search,
  Trash2,
  User as UserIcon,
  Bookmark,
  ShieldAlert,
} from 'lucide-react';
import { communityApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatTile, StatusTag } from '../components/admin/AdminPage';
import { AdminModal } from '../components/admin/AdminModal';
import { Button } from '../components/ui/button';

interface CommunityAuthor {
  id: number;
  displayName: string;
  username: string;
  email?: string;
  photoUrl?: string;
}

interface CommunityPostItem {
  id: number;
  imageUrl: string;
  thumbnailUrl?: string;
  title?: string;
  description?: string;
  width?: number;
  height?: number;
  likesCount: number;
  commentsCount: number;
  savesCount: number;
  isApproved: boolean;
  isReported: boolean;
  createdAt: string;
  author: CommunityAuthor | null;
}

interface ReportItem {
  id: number;
  reason: string;
  createdAt: string;
  reporter: {
    id: number;
    displayName: string;
    username: string;
    email?: string;
  } | null;
  post: {
    id: number;
    imageUrl: string;
    thumbnailUrl?: string;
    title?: string;
    author: {
      id: number;
      displayName: string;
      username: string;
    } | null;
  } | null;
}

export default function Community() {
  const [activeTab, setActiveTab] = useState<'posts' | 'reports'>('posts');
  const [filter, setFilter] = useState<'all' | 'reported' | 'unapproved'>('all');
  const [posts, setPosts] = useState<CommunityPostItem[]>([]);
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [stats, setStats] = useState({
    totalPosts: 0,
    reportedPosts: 0,
    unapprovedPosts: 0,
    totalReports: 0,
  });
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  useEffect(() => {
    void fetchStats();
  }, []);

  useEffect(() => {
    if (activeTab === 'posts') {
      void fetchPosts();
    } else {
      void fetchReports();
    }
  }, [activeTab, filter, page]);

  const fetchStats = async () => {
    try {
      const res = await communityApi.getStats();
      setStats(res.data);
    } catch {
      // ignore stats error
    }
  };

  const fetchPosts = async () => {
    setIsLoading(true);
    try {
      const res = await communityApi.getPosts({
        page,
        limit: 24,
        search: searchQuery,
        filter,
      });
      setPosts(res.data.posts || []);
      setTotalPages(res.data.totalPages || 1);
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Failed to load community posts');
    } finally {
      setIsLoading(false);
    }
  };

  const fetchReports = async () => {
    setIsLoading(true);
    try {
      const res = await communityApi.getReports();
      setReports(res.data.reports || []);
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Failed to load reports');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeletePost = async (id: number) => {
    if (!window.confirm('Are you sure you want to delete this community wallpaper?')) return;
    try {
      setDeletingId(id);
      await communityApi.deletePost(id);
      toast.success('Community post deleted');
      setPosts((prev) => prev.filter((p) => p.id !== id));
      void fetchStats();
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Failed to delete post');
    } finally {
      setDeletingId(null);
    }
  };

  const handleToggleApprove = async (id: number) => {
    try {
      const res = await communityApi.toggleApprove(id);
      setPosts((prev) =>
        prev.map((p) => (p.id === id ? { ...p, isApproved: res.data.isApproved } : p))
      );
      toast.success(res.data.isApproved ? 'Wallpaper approved' : 'Wallpaper hidden');
      void fetchStats();
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Failed to update status');
    }
  };

  const handleDismissReport = async (reportId: number) => {
    try {
      await communityApi.dismissReport(reportId);
      toast.success('Report dismissed');
      setReports((prev) => prev.filter((r) => r.id !== reportId));
      void fetchStats();
    } catch (err: any) {
      toast.error(err.response?.data?.error || 'Failed to dismiss report');
    }
  };

  const filteredPosts = useMemo(() => {
    if (!searchQuery.trim()) return posts;
    const q = searchQuery.toLowerCase();
    return posts.filter(
      (p) =>
        p.title?.toLowerCase().includes(q) ||
        p.description?.toLowerCase().includes(q) ||
        p.author?.displayName?.toLowerCase().includes(q) ||
        p.author?.username?.toLowerCase().includes(q) ||
        p.author?.email?.toLowerCase().includes(q)
    );
  }, [posts, searchQuery]);

  return (
    <AdminPage
      eyebrow="Community Module"
      title="Community Wallpapers"
      subtitle="Review user-uploaded wallpapers, monitor community engagement, and handle moderation reports"
      actions={
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button
            variant="secondary"
            onClick={() => {
              void fetchStats();
              activeTab === 'posts' ? void fetchPosts() : void fetchReports();
            }}
          >
            <RefreshCw size={14} style={{ marginRight: '6px' }} />
            Refresh
          </Button>
        </div>
      }
    >
      {/* ── Stat Tiles ────────────────────────────────────── */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '16px',
          marginBottom: '24px',
        }}
      >
        <StatTile
          label="Total Wallpapers"
          value={stats.totalPosts}
          helper="User-submitted wallpapers"
          tone="blue"
        />
        <StatTile
          label="Flagged / Reported"
          value={stats.reportedPosts}
          helper="Wallpapers reported by users"
          tone="red"
        />
        <StatTile
          label="Unapproved"
          value={stats.unapprovedPosts}
          helper="Wallpapers hidden or pending"
          tone="orange"
        />
        <StatTile
          label="Pending Reports"
          value={stats.totalReports}
          helper="Unresolved violation tickets"
          tone="purple"
        />
      </div>

      {/* ── Top Tabs: Posts vs Reports ───────────────────── */}
      <AdminPanel>
        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: '12px',
            marginBottom: '18px',
            borderBottom: '1px solid #e2e8f0',
            paddingBottom: '14px',
          }}
        >
          {/* Main Tab Switch */}
          <div style={{ display: 'flex', gap: '8px' }}>
            <Button
              variant={activeTab === 'posts' ? 'default' : 'secondary'}
              onClick={() => {
                setActiveTab('posts');
                setPage(1);
              }}
            >
              <ImageIcon size={15} style={{ marginRight: '6px' }} />
              Wallpapers Feed ({stats.totalPosts})
            </Button>
            <Button
              variant={activeTab === 'reports' ? 'destructive' : 'secondary'}
              onClick={() => {
                setActiveTab('reports');
                setPage(1);
              }}
            >
              <ShieldAlert size={15} style={{ marginRight: '6px' }} />
              Reports Queue ({stats.totalReports})
            </Button>
          </div>

          {/* Sub-Filters for Posts */}
          {activeTab === 'posts' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ display: 'flex', gap: '4px' }}>
                {(['all', 'reported', 'unapproved'] as const).map((f) => (
                  <Button
                    key={f}
                    variant={filter === f ? 'default' : 'ghost'}
                    size="sm"
                    onClick={() => {
                      setFilter(f);
                      setPage(1);
                    }}
                  >
                    {f === 'all' && 'All'}
                    {f === 'reported' && `Reported (${stats.reportedPosts})`}
                    {f === 'unapproved' && `Unapproved (${stats.unapprovedPosts})`}
                  </Button>
                ))}
              </div>

              {/* Search Bar */}
              <div style={{ position: 'relative', width: '220px' }}>
                <Search
                  size={14}
                  style={{
                    position: 'absolute',
                    left: '10px',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    color: '#94a3b8',
                  }}
                />
                <input
                  type="text"
                  placeholder="Search title, creator..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && fetchPosts()}
                  style={{
                    width: '100%',
                    padding: '6px 10px 6px 30px',
                    borderRadius: '8px',
                    border: '1px solid #cbd5e1',
                    fontSize: '13px',
                    outline: 'none',
                  }}
                />
              </div>
            </div>
          )}
        </div>

        {/* ── Content: Posts View ──────────────────────────── */}
        {activeTab === 'posts' && (
          <>
            {isLoading ? (
              <div style={{ textAlign: 'center', padding: '60px 0', color: '#64748b' }}>
                Loading community wallpapers...
              </div>
            ) : filteredPosts.length === 0 ? (
              <EmptyState
                title="No Community Wallpapers Found"
                message={
                  filter === 'reported'
                    ? 'No wallpapers have been reported by users. Everything looks clean!'
                    : 'No community wallpapers match your current search criteria.'
                }
              />
            ) : (
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
                  gap: '16px',
                }}
              >
                {filteredPosts.map((post) => (
                  <div
                    key={post.id}
                    style={{
                      borderRadius: '12px',
                      border: '1px solid #e2e8f0',
                      backgroundColor: '#ffffff',
                      overflow: 'hidden',
                      display: 'flex',
                      flexDirection: 'column',
                      boxShadow: '0 2px 6px rgba(0,0,0,0.04)',
                      transition: 'transform 0.15s ease',
                    }}
                  >
                    {/* Image Preview */}
                    <div
                      style={{
                        position: 'relative',
                        aspectRatio: '9 / 16',
                        backgroundColor: '#0f172a',
                        overflow: 'hidden',
                        cursor: 'pointer',
                      }}
                      onClick={() => setPreviewImage(post.imageUrl)}
                    >
                      <img
                        src={post.thumbnailUrl || post.imageUrl}
                        alt={post.title || 'Community Wallpaper'}
                        style={{
                          width: '100%',
                          height: '100%',
                          objectFit: 'cover',
                        }}
                        loading="lazy"
                      />

                      {/* Top Badges */}
                      <div
                        style={{
                          position: 'absolute',
                          top: '8px',
                          left: '8px',
                          right: '8px',
                          display: 'flex',
                          justifyContent: 'space-between',
                          gap: '6px',
                        }}
                      >
                        <StatusTag type={post.isApproved ? 'green' : 'gray'}>
                          {post.isApproved ? 'Live' : 'Hidden'}
                        </StatusTag>
                        {post.isReported && (
                          <StatusTag type="red">
                            <AlertTriangle size={12} style={{ marginRight: '4px' }} />
                            Reported
                          </StatusTag>
                        )}
                      </div>

                      {/* Dimensions Overlay */}
                      {post.width && post.height && (
                        <div
                          style={{
                            position: 'absolute',
                            bottom: '8px',
                            right: '8px',
                            backgroundColor: 'rgba(0,0,0,0.65)',
                            color: '#ffffff',
                            padding: '2px 6px',
                            borderRadius: '4px',
                            fontSize: '11px',
                            fontWeight: 500,
                          }}
                        >
                          {post.width}×{post.height}
                        </div>
                      )}
                    </div>

                    {/* Meta & Creator Info */}
                    <div style={{ padding: '12px', flex: 1, display: 'flex', flexDirection: 'column' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                        {post.author?.photoUrl ? (
                          <img
                            src={post.author.photoUrl}
                            alt=""
                            style={{ width: '26px', height: '26px', borderRadius: '50%', objectFit: 'cover' }}
                          />
                        ) : (
                          <div
                            style={{
                              width: '26px',
                              height: '26px',
                              borderRadius: '50%',
                              backgroundColor: '#e2e8f0',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              color: '#64748b',
                            }}
                          >
                            <UserIcon size={14} />
                          </div>
                        )}
                        <div style={{ overflow: 'hidden', lineHeight: 1.2 }}>
                          <p style={{ fontSize: '13px', fontWeight: 600, color: '#1e293b', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {post.author?.displayName || post.author?.username || 'Unknown Creator'}
                          </p>
                          <p style={{ fontSize: '11px', color: '#94a3b8', margin: 0 }}>
                            @{post.author?.username || 'user'}
                          </p>
                        </div>
                      </div>

                      {post.title && (
                        <p style={{ fontSize: '13px', fontWeight: 500, color: '#334155', margin: '0 0 6px 0' }}>
                          {post.title}
                        </p>
                      )}

                      {/* Engagement Counters */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '12px',
                          fontSize: '12px',
                          color: '#64748b',
                          marginTop: 'auto',
                          paddingTop: '8px',
                          borderTop: '1px solid #f1f5f9',
                        }}
                      >
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Heart size={13} color="#ef4444" /> {post.likesCount}
                        </span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <MessageCircle size={13} color="#3b82f6" /> {post.commentsCount}
                        </span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Bookmark size={13} color="#10b981" /> {post.savesCount}
                        </span>
                      </div>

                      {/* Admin Actions */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          marginTop: '10px',
                          paddingTop: '8px',
                          borderTop: '1px solid #f1f5f9',
                        }}
                      >
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleToggleApprove(post.id)}
                          title={post.isApproved ? 'Hide from community' : 'Approve wallpaper'}
                        >
                          {post.isApproved ? (
                            <>
                              <EyeOff size={14} style={{ marginRight: '4px', color: '#f59e0b' }} />
                              Hide
                            </>
                          ) : (
                            <>
                              <Eye size={14} style={{ marginRight: '4px', color: '#10b981' }} />
                              Approve
                            </>
                          )}
                        </Button>

                        <div style={{ display: 'flex', gap: '4px' }}>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => window.open(post.imageUrl, '_blank')}
                            title="Open full image"
                          >
                            <ExternalLink size={14} color="#64748b" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={deletingId === post.id}
                            onClick={() => handleDeletePost(post.id)}
                            title="Delete permanently"
                          >
                            <Trash2 size={14} color="#ef4444" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Pagination */}
            {totalPages > 1 && (
              <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginTop: '24px' }}>
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={page <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  Previous
                </Button>
                <span style={{ alignSelf: 'center', fontSize: '13px', color: '#64748b' }}>
                  Page {page} of {totalPages}
                </span>
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Next
                </Button>
              </div>
            )}
          </>
        )}

        {/* ── Content: Reports Queue View ──────────────────── */}
        {activeTab === 'reports' && (
          <>
            {isLoading ? (
              <div style={{ textAlign: 'center', padding: '60px 0', color: '#64748b' }}>
                Loading moderation queue...
              </div>
            ) : reports.length === 0 ? (
              <EmptyState
                title="All Clear!"
                message="There are no pending user reports or violations in the moderation queue."
              />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {reports.map((report) => (
                  <div
                    key={report.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '14px 18px',
                      borderRadius: '10px',
                      border: '1px solid #fee2e2',
                      backgroundColor: '#fff5f5',
                      gap: '16px',
                    }}
                  >
                    {/* Reported Post Preview */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                      {report.post ? (
                        <img
                          src={report.post.thumbnailUrl || report.post.imageUrl}
                          alt=""
                          onClick={() => report.post && setPreviewImage(report.post.imageUrl)}
                          style={{
                            width: '48px',
                            height: '64px',
                            objectFit: 'cover',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            border: '1px solid #fca5a5',
                          }}
                        />
                      ) : (
                        <div
                          style={{
                            width: '48px',
                            height: '64px',
                            backgroundColor: '#e2e8f0',
                            borderRadius: '6px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: '#94a3b8',
                            fontSize: '11px',
                          }}
                        >
                          Deleted
                        </div>
                      )}

                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                          <StatusTag type="red">Violation: {report.reason.toUpperCase()}</StatusTag>
                          <span style={{ fontSize: '12px', color: '#94a3b8' }}>
                            Reported on {new Date(report.createdAt).toLocaleDateString()}
                          </span>
                        </div>
                        <p style={{ margin: '0 0 2px 0', fontSize: '13px', fontWeight: 600, color: '#1e293b' }}>
                          Post: {report.post?.title || `ID #${report.post?.id || 'Unknown'}`} (Creator: @{report.post?.author?.username || 'creator'})
                        </p>
                        <p style={{ margin: 0, fontSize: '12px', color: '#64748b' }}>
                          Reported by: <strong style={{ color: '#0f172a' }}>{report.reporter?.displayName || `@${report.reporter?.username || 'user'}`}</strong> ({report.reporter?.email || 'No email'})
                        </p>
                      </div>
                    </div>

                    {/* Actions */}
                    <div style={{ display: 'flex', gap: '8px' }}>
                      {report.post && (
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => {
                            if (report.post?.id) {
                              void handleDeletePost(report.post.id);
                              void handleDismissReport(report.id);
                            }
                          }}
                        >
                          <Trash2 size={14} style={{ marginRight: '6px' }} />
                          Delete Wallpaper
                        </Button>
                      )}
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={() => handleDismissReport(report.id)}
                      >
                        <CheckCircle2 size={14} style={{ marginRight: '6px', color: '#10b981' }} />
                        Dismiss
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </AdminPanel>

      {/* ── Image Preview Modal ──────────────────────────── */}
      {previewImage && (
        <AdminModal
          open={!!previewImage}
          onClose={() => setPreviewImage(null)}
          title="Community Wallpaper Preview"
          noFooter
        >
          <div style={{ textAlign: 'center', maxHeight: '80vh', overflow: 'auto' }}>
            <img
              src={previewImage}
              alt="Preview"
              style={{
                maxWidth: '100%',
                maxHeight: '70vh',
                objectFit: 'contain',
                borderRadius: '8px',
              }}
            />
            <div style={{ marginTop: '14px' }}>
              <Button onClick={() => window.open(previewImage, '_blank')}>
                <ExternalLink size={14} style={{ marginRight: '6px' }} />
                Open Full Resolution
              </Button>
            </div>
          </div>
        </AdminModal>
      )}
    </AdminPage>
  );
}
